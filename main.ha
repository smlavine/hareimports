use fmt;
use hare::lex;
use io;
use os;

fn printlex(lexp: *lex::lexer) (void | lex::error) = {
	for (let i = 0; true; i += 1) {
		const token = lex::lex(lexp)?;

		if (token.0 == lex::ltok::EOF)
			break;

		const comment = lex::comment(lexp);
		if (comment != "")
			fmt::printfln("COMMENTED: \"{}\"", comment)!;

		fmt::print(lex::tokstr(token))!;
		switch (token.0) {
		case lex::ltok::SEMICOLON =>
			fmt::println()!;
		case lex::ltok::NAME =>
			fmt::print("<< (NAME) ")!;
		case =>
			fmt::print(" ")!;
		};
	};
};

export fn main() void = {
	const lexer = lex::init(os::stdin, "<stdin>", lex::flags::COMMENTS);

	match (printlex(&lexer)) {
	case void => void;
	case let e: lex::error =>
		fmt::fatalf("lex error: {}", lex::strerror(e));
	};
};
