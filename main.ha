use fmt;
use hare::lex;
use io;
use os;

fn printlex(lexp: *lex::lexer) void = {
	for (let i = 0; true; i += 1) {
		const token = match (lex::lex(lexp)) {
		case let t: lex::token =>
			yield t;
		case let e: lex::error =>
			fmt::fatalf("{}: lex error ({}): {}",
				os::args[0], i, lex::strerror(e));
		};

		if (token.0 == lex::ltok::EOF)
			break;

		const comment = lex::comment(lexp);
		if (comment != "")
			fmt::printfln("COMMENTED: \"{}\"", comment)!;

		fmt::print(lex::tokstr(token))!;
		if (token.0 == lex::ltok::SEMICOLON) {
			fmt::println()!;
		} else {
			fmt::print(" ")!;
		};
	};
};

export fn main() void = {
	const lexer = lex::init(os::stdin, "<stdin>", lex::flags::COMMENTS);

	printlex(&lexer);
};
