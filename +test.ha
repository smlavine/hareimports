// hareimports - Hare import manager
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

use bufio;
use hare::lex;
use hare::parse;
use io;
use os;
use strio;

def TEST_SOURCE: str = `
use fmt;
use io;

export fn main() void = {
	fmt::println("Hello")!;
};
`;

// Makes a source_file from the constant source str defined above.
fn mktestsource() source_file = {
	const memstream = bufio::fixed(*(&TEST_SOURCE: *[]u8), io::mode::READ);
	const lexer = lex::init(&memstream, "TEST_SOURCE");
	return source_file {
		path = "TEST_SOURCE",
		subunit = parse::subunit(&lexer)!,
	};
};

@test fn test_list() void = {
	// un poco fuckery; since list() writes to os::stdout, we temporarily
	// capture os::stdout with a strio stream to test its contents.
	const orig_stdout = os::stdout;
	const stream = strio::dynamic();
	defer io::close(&stream)!;
	os::stdout = &stream;

	const source = mktestsource();
	list(source);
	os::stdout = orig_stdout;

	assert(strio::string(&stream) == "TEST_SOURCE:\nfmt\nio\n");
};
