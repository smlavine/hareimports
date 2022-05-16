use fmt;
use fs;
use hare::lex;
use io;
use os;

export fn main() void = {
	// tuple assignment isn't implemented yet.
	//let (file, path): (io::handle, str) = switch(len(os::args)) {
	const filepath: (io::handle, str) = switch (len(os::args)) {
	case 0, 1 =>
		yield (os::stdin, "<stdin>");
	case 2 =>
		const file = match (os::open(os::args[1])) {
		case let file: io::file =>
			yield file;
		case let e: fs::error =>
			fmt::fatalf("{}: cannot open {}: {}",
				os::args[0], os::args[1], fs::strerror(e));
		};
		yield (file, os::args[1]);
	case =>
		fmt::fatal("usage: hareimports [file]");
	};
	// won't be necessary once tuple assignment is implemented.
	const file = filepath.0, path = filepath.1;

	const lexer = lex::init(file, path, lex::flags::COMMENTS);
	for (let i = 0; true; i += 1) {
		const token = match(lex::lex(&lexer)) {
		case let t: lex::token =>
			yield t;
		case lex::error =>
			fmt::fatalf("{}: error lexing token {}.",
				os::args[0], i);
		};

		if (token.0 == lex::ltok::EOF)
			break;

		fmt::print(lex::tokstr(token))!;
		if (token.0 == lex::ltok::SEMICOLON) {
			fmt::println()!;
		} else {
			fmt::print(" ")!;
		};

		//fmt::printf(lex::comment(&lexer))!;
	};

};
