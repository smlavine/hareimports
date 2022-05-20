use fmt;
use hare::lex;
use io;
use os;
use strio;
use strings;

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

// Returns a lex::syntax error from the location and string representation of
// the provided token.
fn badtoken(t: lex::token) lex::syntax = (t.2, lex::tokstr(t));

// Parses a single import statement from the provided [[hare::lex::lexer]].
// Precondition: the use keyword MUST have already been lexed.
// Only allow an alias to be parsed if the alias parameter is empty.
// Returns an [[import]] on success, or [[hare::lex::error]] on failure.
fn getimport(lexp: *lex::lexer, alias: str) (import | lex::error) = {
	// USE
	// <opt>
	// NAME
	// EQUAL
	// </opt>
	// NAME
	// DOUBLE_COLON
	// SEMICOLON

	let module_builder = strio::dynamic();
	defer io::close(&module_builder)!;

	// The first token has to be a name: either the beginning of
	// an import-alias or the beginning of an identifier.
	// See also §6.4 (Identifiers).
	const first = lex::lex(lexp)?;
	if (first.0 != lex::ltok::NAME)
		return badtoken(first);

	// TODO: concat to module_builder? But really only needed after
	// the second case.

	const second = lex::lex(lexp)?;
	switch (second.0) {
	case lex::ltok::SEMICOLON =>
		// Unaliased top-level (i.e. not a submodule) import
		return import {
			location = first.2,
			module = strings::dup(lex::tokstr(first)),
			alias = alias,
		};
	case lex::ltok::EQUAL =>
		// Import alias
		if (alias == "") {
			alias = strings::dup(lex::tokstr(first));
			return getimport(lexp, alias);
		} else {
			return badtoken(second);
		};
	case lex::ltok::DOUBLE_COLON =>
		// TODO: parse submodules and unqualified forms
		//
		// temporary unlex call, so we can continue past submodule
		// import. The loop in getimports requires the next token to
		// be a use keyword to continue.
		lex::unlex(lexp, (lex::ltok::USE, "use", first.2));
		// for now, copy from SEMICOLON case, parsing only top level of
		// module.
		return import {
			location = first.2,
			module = strings::dup(lex::tokstr(first)),
			alias = alias,
		};
	case =>
		return badtoken(second);
	};

	//abort("end of getimport() is unreachable");
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
