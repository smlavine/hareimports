use fmt;
use hare::lex;
use io;
use os;

// The relevant grammar from the Hare spec, 6.12 (Units):
//
// sub-unit:
// 	imports(opt) declarations(opt)
//
// imports:
// 	use-statement
// 	use-statement imports
//
// use-statement:
// 	use import-alias(opt) identifier ;
// 	use import-alias(opt) identifier :: { member-list } ;
// 	use identifier :: * ;
//
// import-alias:
// 	name =
//
// member-list:
// 	member ,(opt)
// 	member , member-list
//
// member:
// 	name
// 	name = name
//

// Represents a module that has been imported into the sub-unit.
export type import = struct {
	module: str,
	importalias: str,
	// TODO: handle second and third (unqualified) types of imports.
};

// Frees a slice of [[import]]s. See [[strings::freeall]].
export fn imports_freeall(imports: []import) void = {
	for (let i = 0z; i < len(imports); i += 1) {
		free(imports[i].module);
		free(imports[i].importalias);
	};
	free(imports);
};

// Returns the provided token if it matches any of the provided
// [[hare::lex::ltok]]s; otherwise returns a [[hare::lex::syntax]] error.
fn checktok(t: lex::token, v: lex::ltok...) (lex::token | lex::syntax) = {
	for (let i = 0z; i < len(v); i += 1)
		if (t.0 == v[i])
			return t;

	return (t.2, lex::tokstr(t));
};

// Returns a slice of [[import]]s or a [[hare::lex::error]]. The slice must be
// freed using [[imports_freeall]].
//
// See §6.12 (Units) of the Hare spec for more information.
export fn getimports(lexp: *lex::lexer) ([]import | lex::error) = {
	// USE
	// <opt>
	// NAME
	// EQUAL
	// </opt>
	// NAME
	// DOUBLE_COLON
	// SEMICOLON

	let imports: []import = [];
	// errdefer free(imports); // currently leaks memory on lex::error

	for (lex::lex(lexp)?.0 == lex::ltok::USE) {
		const t = checktok(lex::lex(lexp)?, lex::ltok::NAME)?;

		checktok(lex::lex(lexp)?, lex::ltok::SEMICOLON)?;
	};

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
};
