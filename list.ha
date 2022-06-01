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
use hare::ast;
use hare::unparse;

// Lists the imports of the given file, in the order they are imported.
fn list(source: source_file) void = {
	const u: *ast::subunit = &source; // sub-typing
	fmt::printfln("{}:", source.path)!;
	for (let i = 0z; i < len(u.imports); i += 1) {
		const s = unparse::identstr(u.imports[i].ident);
		defer free(s);

		switch (u.imports[i].mode) {
		case ast::import_mode::ALIAS =>
			fmt::printfln("{} (= {})", u.imports[i].alias, s)!;
		case =>
			fmt::println(s)!;
		};
	};
};
