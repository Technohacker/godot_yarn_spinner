extends Reference

# Operator names that contain other operator names should be placed first to
# avoid replacing parts of the larger operator name with the smaller one
# TODO: Relying on dictionary order is probably a bad idea
const TEXT_TO_SYMBOL = {
	# Relational
	"neq": "!=",
	"eq": "==",
	"is": "==",
	"gte": ">=",
	"lte": "<=",
	"gt": ">",
	"lt": "<",
	# Logical
	"xor": "^",
	"or": "||",
	"and": "&&",
	# Assignment
	"to": "="
}

const ARITH_OPERATORS = ["+", "-", "*", "/", "%", "(", ")"]

"""
Converts a token array into a GDScript expression
"""
func tokens_to_expression(tokens: Array) -> String:
	var expression = ""

	# According to Yarn docs, valid expressions include arithmetic, logical, relational operators, variables and literals
	for token in tokens:
		# Typing
		token = token as String
		var token_parts = []

		# Add spaces around operators if we're not in a string just to make sure we parse them correctly
		if !token.begins_with("\""):
			for op_text in TEXT_TO_SYMBOL.keys():
				token = token.replace(
					op_text,
					" {op} ".format({
						"op": TEXT_TO_SYMBOL[op_text]
					})
				)

			for op in ARITH_OPERATORS:
				token = token.replace(op, " %s " % op)

			# Place the individual parts of the token for appending
			token_parts.append_array(token.split(" ", false))
		else:
			# String literal
			token_parts.append(token)

		# Append each token part together
		for part in token_parts:
			# Any special cases are handled here
			if part.begins_with("$"):
				# Variable. Convert to a variables dictionary lookup
				expression += "(variables[\"{variable_name}\"]) ".format({
					"variable_name": part
				})
				continue

			expression += part + " "

	return expression.strip_edges()
