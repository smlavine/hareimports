// hareimports - manage imports for hare source files
// Copyright (C) 2022 Sebastian LaVine <mail@smlavine.com>
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
use hare::lex;
use io;
use os;
use strio;
use strings;

// Represents a module that has been imported into the sub-unit.
export type import = struct {
	// location of the first token in import after the use keyword
	location: lex::location,
	module: str,
	alias: str,
	// TODO: handle second and third (unqualified) types of imports.
};

// Frees a slice of [[import]]s. See [[strings::freeall]].
export fn imports_freeall(imports: []import) void = {
	for (let i = 0z; i < len(imports); i += 1) {
		// TODO: imports[i].location?
		free(imports[i].module);
		free(imports[i].alias);
	};
	free(imports);
};

// Returns a [[lex::syntax]] error from the location and string representation
// of the provided token.
fn badtoken(t: lex::token) lex::syntax = (t.2, lex::tokstr(t));

// Parses a single import statement from the provided [[hare::lex::lexer]].
// Precondition: the use keyword MUST have already been lexed.
// Only allow an alias to be parsed if the alias parameter is empty.
// Returns an [[import]] on success, or [[hare::lex::error]] on failure.
fn getimport(lexp: *lex::lexer, alias: str) (import | lex::error) = {
	// The first token has to be a name: either the beginning of
	// an import-alias or the beginning of an identifier.
	// See also §6.4 (Identifiers).
	const first = lex::lex(lexp)?;
	if (first.0 != lex::ltok::NAME)
		return badtoken(first);

	let import = import {
		location = first.2,
		module = "",
		alias = alias,
	};

	let module_builder = strio::dynamic();
	defer io::close(&module_builder)!;

	const second = lex::lex(lexp)?;
	switch (second.0) {
	case lex::ltok::SEMICOLON =>
		// top-level (i.e. not a submodule) import
		import.module = strings::dup(lex::tokstr(first));
		return import;
	case lex::ltok::EQUAL =>
		// Import alias
		if (alias == "") {
			return getimport(lexp,
				strings::dup(lex::tokstr(first)));
		};
		return badtoken(second);
	case lex::ltok::DOUBLE_COLON =>
		strio::concat(&module_builder, lex::tokstr(first), "::")!;
	case =>
		return badtoken(second);
	};

	// The previous token was a DOUBLE_COLON.

	const third = lex::lex(lexp)?;
	switch (third.0) {
	case lex::ltok::LBRACE =>
		abort("member-list import (§6.12.4) not supported yet.");
	case lex::ltok::TIMES =>
		abort("unqualified import (§6.12.6) not supported yet.");
	case lex::ltok::NAME =>
		strio::concat(&module_builder, lex::tokstr(third))!;
	case =>
		return badtoken(third);
	};

	for (true) {
		const possible_dcolon = lex::lex(lexp)?;
		switch (possible_dcolon.0) {
		case lex::ltok::DOUBLE_COLON =>
			strio::concat(&module_builder, "::")!;
		case lex::ltok::SEMICOLON =>
			break;
		case =>
			return badtoken(possible_dcolon);
		};

		const name = lex::lex(lexp)?;
		switch (name.0) {
		case lex::ltok::NAME =>
			strio::concat(&module_builder, lex::tokstr(name))!;
		case =>
			return badtoken(name);
		};
	};

	import.module = strings::dup(strio::string(&module_builder));
	return import;
};

// Returns a slice of [[import]]s or a [[hare::lex::error]]. The slice must be
// freed using [[imports_freeall]].
//
// See §6.12 (Units) of the Hare spec for more information.
export fn getimports(lexp: *lex::lexer) ([]import | lex::error) = {
	let imports: []import = [];
	// errdefer free(imports); // currently leaks memory on lex::error

	for (lex::lex(lexp)?.0 == lex::ltok::USE)
		append(imports, getimport(lexp, "")?);

	return imports;
};

export fn main() void = {
	const lexer = lex::init(os::stdin, "<stdin>", lex::flags::COMMENTS);

	let imports = match (getimports(&lexer)) {
	case let s: []import =>
		yield s;
	case let e: lex::error =>
		fmt::fatalf(lex::strerror(e));
	};
	defer imports_freeall(imports);

	for (let i = 0z; i < len(imports); i += 1)
		fmt::printfln("{} {}", imports[i].module, imports[i].alias)!;
};
