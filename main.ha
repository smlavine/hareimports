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
use hare::ast;
use hare::lex;
use hare::parse;
use os;
use strings;

export fn main() void = {
	const lexer = lex::init(os::stdin, "<stdin>", lex::flags::NONE);

	const subunit = match (parse::subunit(&lexer)) {
	case let s: ast::subunit =>
		yield s;
	case let e: parse::error =>
		fmt::fatalf(parse::strerror(e));
	};
	defer ast::subunit_finish(subunit);

	for (let i = 0z; i < len(subunit.imports); i += 1) {
		const m = &subunit.imports[i];

		const joined_ident = strings::join("::", m.ident...);
		defer free(joined_ident);

		switch (m.mode) {
		case ast::import_mode::ALIAS =>
			fmt::printfln("{} (= {})", m.alias, joined_ident)!;
		case =>
			fmt::println(joined_ident)!;
		};
	};
};
