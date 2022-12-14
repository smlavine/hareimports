// hareimports - Hare import manager
// Copyright (C) 2022 Sebastian LaVine <mail@smlavine.com>
// Copyright (C) 2022 Sebastian <sebastian@sebsite.pw>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 only.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.

use fmt;
use getopt;
use hare::ast;
use hare::lex;
use hare::module;
use hare::parse;
use hare::unparse;
use io;
use os;

type source_file = struct {
	subunit: ast::subunit,
	path: str,
};

// Lists the imports of the given file, in the order they are imported.
export fn list(source: source_file) void = {
	const u: *ast::subunit = &source; // sub-typing
	fmt::printfln("{}:", source.path)!;
	for (let i = 0z; i < len(u.imports); i += 1) {
		const s = unparse::identstr(u.imports[i].ident);
		defer free(s);

		switch (u.imports[i].mode) {
		case ast::import_mode::IDENT =>
			fmt::println(s)!;
		case ast::import_mode::ALIAS =>
			fmt::printfln("{} = {}", u.imports[i].alias, s)!;
		case ast::import_mode::MEMBERS =>
			fmt::printf("{}::{{", s)!;
			const nlim = len(u.imports[i].objects) - 1;
			for (let n = 0z; n < nlim; n += 1)
				fmt::printf("{}, ",
					u.imports[i].objects[n].1)!;
			fmt::printfln("{}}}", u.imports[i].objects[nlim].1)!;
		case ast::import_mode::WILDCARD =>
			fmt::printfln("{}::*", s)!;
		};
	};
};

export fn main() void = {
	const help: []getopt::help = [
		"Hare import manager",
		('a', "operate on all source files in module"),
		('d', "display diffs"),
		('i', "edit files in place"),
		('l', "list source file imports (default)"),
		('m', "module path", "use a module that isn't the cwd"),
		('T', "tags...", "set tags"),
		"files... (XXX: must be full paths for now)"
	];
	const cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);

	let use_all = false;

	let module_path = ".";

	let tags: []module::tag = [];
	defer module::tags_free(tags);

	// XXX: have a slice of operations to do in order, instead of just
	// allowing one?
	let op: *fn(_: source_file) void = &list;

	for (let i = 0z; i < len(cmd.opts); i += 1) {
		const opt = cmd.opts[i];
		// TODO: parse other options to indicate different operations
		switch (opt.0) {
		case 'a' =>
			use_all = true;
		case 'd' =>
			op = &diff;
		case 'i' =>
			op = &in_place;
		case 'l' =>
			op = &list;
		case 'm' =>
			module_path = opt.1;
		case 'T' =>
			// XXX: should accept multiple -T options, and maybe
			// also -X
			// See addtags and deltags in cmd/hare/subcmds.ha

			// This flag is needed for hareimports to know whether
			// an indentifier refers to a remote module/enum or a
			// local enum only defined within a tagset.

			if (len(tags) > 0) {
				getopt::printusage(os::stderr,
					"hareimports", help);
				os::exit(1);
			};
			tags = match (module::parsetags(opt.1)) {
			case void =>
				fmt::fatal("Invalid tag set");
			case let t: []module::tag =>
				yield t;
			};
		case => abort("impossible getopt case reached");
		};
	};

	const mctx = module::context_init(tags, [], "");
	defer module::context_finish(&mctx);

	const ver = match (module::scan(&mctx, module_path)) {
	case let v: module::version =>
		yield v;
	case let e: module::error =>
		fmt::fatal(module::strerror(e));
	};

	// TODO: enum slice

	let sources: []source_file = [];
	defer free(sources);

	for (let i = 0z; i < len(ver.inputs); i += 1) {
		const input = ver.inputs[i];
		if (input.ft != module::filetype::HARE) {
			continue;
		};
		const f = os::open(input.path)!;
		defer io::close(f)!;

		const lexer = lex::init(f, input.path);
		const subunit = match (parse::subunit(&lexer)) {
		case let s: ast::subunit =>
			yield s;
		case let e: parse::error =>
			fmt::fatal(parse::strerror(e));
		};

		append(sources, source_file {
			path = input.path,
			subunit = subunit,
		});

		// TODO: look for enums declared in this subunit; add to slice
		// of module enums declared above.
	};

	let op_indices: []size = [];
	if (use_all) {
		for (let i = 0z; i < len(sources); i += 1)
			append(op_indices, i);
	} else if (len(cmd.args) == 0) {
		fmt::errorln("error: no files provided")!;
		getopt::printusage(os::stderr, "hareimports", help);
		os::exit(1);
	} else {
		for (let i = 0z; i < len(sources); i += 1) {
			for (let j = 0z; j < len(cmd.args); j += 1) {
				// TODO: check whether the paths resolve to the
				// same file; right now the absolute path must
				// be provided.
				if (sources[i].path == cmd.args[j])
					append(op_indices, i);
			};
		};
	};
	defer free(op_indices);

	for (let n = 0z; n < len(op_indices); n += 1) {
		op(sources[op_indices[n]]);
		ast::subunit_finish(sources[op_indices[n]].subunit);
	};
};
