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

// Lists the imports of a given file, in the order they are imported.
fn list(path: str, subunit: ast::subunit) void = {
	fmt::printfln("{}:", path)!;
	for (let i = 0z; i < len(subunit.imports); i += 1) {
		const m = &subunit.imports[i];
		const s = unparse::identstr(m.ident);
		defer free(s);

		switch (m.mode) {
		case ast::import_mode::ALIAS =>
			fmt::printfln("{} (= {})", m.alias, s)!;
		case =>
			fmt::println(s)!;
		};
	};
};

export fn main() void = {
	const help: []getopt::help = [
		"Hare import manager",
		('T', "tags...", "set tags"),
		"[<path>]"
	];
	const cmd = getopt::parse(os::args, help...);
	defer getopt::finish(&cmd);

	let tags: []module::tag = [];
	defer module::tags_free(tags);

	// XXX: have a slice of operations to do in order, instead of just
	// allowing one?
	let op: *fn(path: str, subunit: ast::subunit) void = &list;

	for (let i = 0z; i < len(cmd.opts); i += 1) {
		const opt = cmd.opts[i];
		// TODO: parse other options to indicate different operations
		switch (opt.0) {
		// XXX: should accept multiple -T options, and maybe also -X
		// See addtags and deltags in cmd/hare/subcmds.ha
		case 'T' =>
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

	const path = switch (len(cmd.args)) {
	case 0 =>
		yield ".";
	case 1 =>
		yield cmd.args[0];
	case =>
		getopt::printusage(os::stderr, "hareimports", help);
		os::exit(1);
	};

	const mctx = module::context_init(tags, [], "");
	defer module::context_finish(&mctx);

	const ver = match (module::scan(&mctx, path)) {
	case let v: module::version =>
		yield v;
	case let e: module::error =>
		fmt::fatal(module::strerror(e));
	};

	// TODO: enum slice

	let sourcefiles: [](str, ast::subunit) = [];
	defer free(sourcefiles);

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

		append(sourcefiles, (input.path, subunit));

		// TODO: look for enums declared in this subunit; add to slice
		// of module enums declared above.
	};

	// We must look for enums in all source files before processing
	// the imports.

	for (let i = 0z; i < len(sourcefiles); i += 1) {
		// TODO: parse subunit.decls to see if imports are unused or
		// if unimported modules are used
		null;
	};

	for (let i = 0z; i < len(sourcefiles); i += 1) {
		op(sourcefiles[i].0, sourcefiles[i].1);
		ast::subunit_finish(sourcefiles[i].1);
	};
};
