package hu.blackbelt.judo.meta.jql.runtime

import hu.blackbelt.judo.meta.jql.jqldsl.BinaryOperation
import hu.blackbelt.judo.meta.jql.jqldsl.BooleanLiteral
import hu.blackbelt.judo.meta.jql.jqldsl.DateLiteral
import hu.blackbelt.judo.meta.jql.jqldsl.DecimalLiteral
import hu.blackbelt.judo.meta.jql.jqldsl.FunctionCall
import hu.blackbelt.judo.meta.jql.jqldsl.IntegerLiteral
import hu.blackbelt.judo.meta.jql.jqldsl.JqlExpression
import hu.blackbelt.judo.meta.jql.jqldsl.MeasuredLiteral
import hu.blackbelt.judo.meta.jql.jqldsl.StringLiteral
import hu.blackbelt.judo.meta.jql.jqldsl.TernaryOperation
import hu.blackbelt.judo.meta.jql.jqldsl.TimestampLiteral
import hu.blackbelt.judo.meta.jql.jqldsl.UnaryOperation
import java.math.BigDecimal
import java.math.BigInteger
import org.junit.jupiter.api.Test

import static extension org.junit.jupiter.api.Assertions.*
import hu.blackbelt.judo.meta.jql.jqldsl.FunctionedExpression
import hu.blackbelt.judo.meta.jql.jqldsl.NavigationExpression
import hu.blackbelt.judo.meta.jql.jqldsl.Feature
import hu.blackbelt.judo.meta.jql.jqldsl.QualifiedName
import hu.blackbelt.judo.meta.jql.jqldsl.TimeLiteral

class JqlDslGrammarTest {

	JqlParser parser = new JqlParser

	@Test
	def void stringLiterals() {
		var string = "'hello'".parse
		"hello".assertEquals(string.expressionValue)

		string = '''
			"hello"
		'''.parse
		"hello".assertEquals(string.expressionValue)
	}

	@Test
	def void stringEscaping() {
		"___'hello___".assertEquals(("'___\\'hello___'".parse.expressionValue))
		'___"hello"___'.assertEquals(('"___\\"hello\\"___"'.parse.expressionValue))
	}

	@Test
	def void booleanLiterals() {
		var literal = "true".parse as BooleanLiteral
		assertTrue(literal.isIsTrue)
		literal = "false".parse as BooleanLiteral
		assertFalse(literal.isIsTrue)
	}

	@Test
	def void numericLiterals() {
		var integer = parser.parseString("123") as IntegerLiteral
		BigInteger.valueOf(123).assertEquals(integer.expressionValue)

		integer = parser.parseString("123456789012345678901234567890") as IntegerLiteral
		new BigInteger("123456789012345678901234567890").assertEquals(integer.expressionValue)

		var decimal = parser.parseString("123.0") as DecimalLiteral
		new BigDecimal("123.0").assertEquals(decimal.expressionValue)
	}

	@Test
	def void arithmeticOperations() {
		var operation = "a/b".parse as BinaryOperation
		"/".assertEquals(operation.operator)

		operation = "a div b".parse as BinaryOperation
		"div".assertEquals(operation.operator)

		operation = "a DIV b".parse as BinaryOperation
		"DIV".assertEquals(operation.operator)

		operation = "a mod b".parse as BinaryOperation
		"mod".assertEquals(operation.operator)

		operation = "a * b".parse as BinaryOperation
		"*".assertEquals(operation.operator)

		operation = "a + b".parse as BinaryOperation
		"+".assertEquals(operation.operator)

		operation = "'a' + \"b\"".parse as BinaryOperation
		"+".assertEquals(operation.operator)

		operation = "a - b".parse as BinaryOperation
		"-".assertEquals(operation.operator)

		operation = "a^b".parse as BinaryOperation
		"^".assertEquals(operation.operator)

		operation = "-1.5 * 10^-200".parse as BinaryOperation
		"(* (- 1.5) (^ 10 (- 200)))".assertEquals(operation.asString)

		operation = "a ^ b * c + d / e".parse as BinaryOperation
		"(+ (* (^ a b) c) (/ d e))".assertEquals(operation.asString)
	}

	@Test
	def void unaryExpressions() {
		var exp = parser.parseString("-100") as UnaryOperation
		"-".assertEquals(exp.operator)
		BigInteger.valueOf(100).assertEquals(exp.operand.expressionValue)

		exp = parser.parseString("not true") as UnaryOperation
		"not".assertEquals(exp.operator)
		true.assertEquals(exp.operand.expressionValue)

		exp = parser.parseString("Not True") as UnaryOperation
		"Not".assertEquals(exp.operator)
		true.assertEquals(exp.operand.expressionValue)
	}

	@Test
	def void ifElse() {
		val exp = "a ? b : c".parse as TernaryOperation
		"a".assertEquals(exp.condition.asString)
		"b".assertEquals(exp.thenExpression.asString)
		"c".assertEquals(exp.elseExpression.asString)
		"(if a b c)".assertEquals(exp.asString)

		val conditionThen = "a<1 ? b<2 : c>3".parse as TernaryOperation
		"(< a 1)".assertEquals(conditionThen.condition.asString)
		"(if (< a 1) (< b 2) (> c 3))".assertEquals(conditionThen.asString)

		// right-associtivity tests
		val combinedExp = "a ? b : c ? d : e".parse as TernaryOperation
		"(if a b (if c d e))".assertEquals(combinedExp.asString)

		val parenExp = "a ? b : (c ? d : e)".parse as TernaryOperation
		"(if a b (if c d e))".assertEquals(parenExp.asString)

		val hardExpParen = "a ? (b ? c : d) : (e ? (f ? g : h) : (i ? j : (k ? l : m))) ".parse as TernaryOperation
		"(if a (if b c d) (if e (if f g h) (if i j (if k l m))))".assertEquals(hardExpParen.asString)
		val hardExp = "a<0 ? b==q ? c : d : e ? f ? g : h : i ? j : k == q xor r ? l and o or p : m implies n ".
			parse as TernaryOperation
		"(if (< a 0) (if (== b q) c d) (if e (if f g h) (if i j (if (xor (== k q) r) (or (and l o) p) (implies m n)))))".
			assertEquals(hardExp.asString)
	}

	@Test
	def void logicalPrecedence() {
		"(or a (not b))".assertEquals("a or not b".parse.asString)
		"(or a (and b c))".assertEquals("a or b and c".parse.asString)
		"(or (and a b) c)".assertEquals("a and b or c".parse.asString)
		"(or (and a (not b)) (not c))".assertEquals("a and not b or not c".parse.asString)
		"(or (and a (not b)) (not c))".assertEquals("(a and not b) or not c".parse.asString)
		"(and a (not (or b (not c))))".assertEquals("a and not (b or not c)".parse.asString)
		"(and a (or (not b) (not c)))".assertEquals("a and (not b or not c)".parse.asString)

		"(xor a b)".assertEquals("a xor b".parse.asString)
		"(xor a (and b c))".assertEquals("a xor b and c".parse.asString)
		"(xor (and a b) c)".assertEquals("a and b xor c".parse.asString)
		"(or (xor a b) c)".assertEquals("a xor b or c".parse.asString)
		"(or a (xor b c))".assertEquals("a or b xor c".parse.asString)

		"(implies a b)".assertEquals("a implies b".parse.asString)
		"(implies a (xor b c))".assertEquals("a implies b xor c".parse.asString)
		"(implies (or a b) (xor c d))".assertEquals("a or b implies c xor d".parse.asString)

		"(implies a (or b (xor c (and d (not e)))))".assertEquals("a implies b or c xor d and not e".parse.asString)
		"(implies (or (xor (and (not a) b) c) d) e)".assertEquals("not a and b xor c or d implies e".parse.asString)

		"(or (!= a b) (== b c))".assertEquals("a != b or b == c".parse.asString)
		"(implies (and (!= a b) (== b c)) (or (<= c d) (>= d e)))".assertEquals(
			"a != b and b == c implies c <= d or d >= e".parse.asString)

		"(== (< a b) (< c d))".assertEquals("a<b == c<d".parse.asString)

		"(and (== a b) c)".assertEquals("a == b and c".parse.asString)
		"(or (== a b) c)".assertEquals("a == b or c".parse.asString)
		"(xor (== a b) c)".assertEquals("a == b xor c".parse.asString)
	}

    def dispatch String asString(FunctionCall functionCall) {
        val result = new StringBuilder();
        result.append("!"+functionCall.function.name+"(")
        functionCall.function.parameters.forEach [ parameter, i |
            result.append(parameter.expression.asString)
            if (parameter.parameterExtension !== null) {
                result.append(" " + parameter.parameterExtension)
            }
            if (i < functionCall.function.parameters.size - 1) {
                result.append(",")
            }
        ]
        result.append(")")
        for (feature : functionCall.features) {
                result.append("." + feature.name)
        }
        if (functionCall.call !== null) {
            result.append(functionCall.call.asString);
        }
        return result.toString
    }

	def dispatch String asString(FunctionedExpression fun) {
		return String.format("%s%s", fun.operand.asString, fun.functionCall.asString)
	}
	
   def dispatch String asString(Feature fun) {
       return "."+fun.name
    }
	
   def dispatch String asString(QualifiedName exp) {
       '''«IF (!exp.namespaceElements.isEmpty)»«String.join("::", exp.namespaceElements)»::«ENDIF»«exp.name»'''
    }
    
	def dispatch String asString(JqlExpression exp) {
		val result = new StringBuilder();
		if (exp instanceof BinaryOperation) {
			result.append(String.format("(%s ", exp.operator))
			result.append(exp.leftOperand.asString)
			result.append(" ")
			result.append(exp.rightOperand.asString)
			result.append(")")
		} else if (exp instanceof FunctionedExpression) {
		    result.append(exp.asString)
		} else if (exp instanceof NavigationExpression) {
		    if (exp.base != null) {
		      result.append(exp.base.asString)  
		    }
		    if (exp.QName != null) {
		        result.append(exp.QName.asString);
		    }
		    for (feature : exp.features) {
		        result.append(feature.asString)
		    }
	    } else if (exp instanceof UnaryOperation) {
			result.append(String.format("(%s %s)", exp.operator, exp.operand.asString))
		} else if (exp instanceof TernaryOperation) {
			result.append(String.format("(if %s %s %s)", exp.condition.asString, exp.thenExpression.asString,
				exp.elseExpression.asString))
		} else {
			result.append(exp.expressionValue)
		}
		return result.toString
	}

	@Test
	def void dateLiterals() {
		var date = parser.parseString("`2001-09-12`") as DateLiteral
		"2001-09-12".assertEquals(date.value)
	}

	@Test
	def void timeLiterals() {
		var parsedTime = parser.parseString("`11:11`") as TimeLiteral
		"11:11".assertEquals(parsedTime.value)
		
		parsedTime = parser.parseString("`11:11:11`") as TimeLiteral
		"11:11:11".assertEquals(parsedTime.value)
		
		parsedTime = parser.parseString("`11:11:11.111`") as TimeLiteral
		"11:11:11.111".assertEquals(parsedTime.value)
	}
	
	@Test
	def void timestampLiterals() {
		var parsedTimestamp = parser.parseString("`2023-03-17T11:11`") as TimestampLiteral
		"2023-03-17T11:11".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11Z`") as TimestampLiteral
		"2023-03-17T11:11Z".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11+01`") as TimestampLiteral
		"2023-03-17T11:11+01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11-01`") as TimestampLiteral
		"2023-03-17T11:11-01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11+01:01`") as TimestampLiteral
		"2023-03-17T11:11+01:01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11-01:01`") as TimestampLiteral
		"2023-03-17T11:11-01:01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11`") as TimestampLiteral
		"2023-03-17T11:11:11".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11Z`") as TimestampLiteral
		"2023-03-17T11:11:11Z".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11+01`") as TimestampLiteral
		"2023-03-17T11:11:11+01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11-01`") as TimestampLiteral
		"2023-03-17T11:11:11-01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11+01:01`") as TimestampLiteral
		"2023-03-17T11:11:11+01:01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11-01:01`") as TimestampLiteral
		"2023-03-17T11:11:11-01:01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11.111`") as TimestampLiteral
		"2023-03-17T11:11:11.111".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11.111Z`") as TimestampLiteral
		"2023-03-17T11:11:11.111Z".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11.111+01`") as TimestampLiteral
		"2023-03-17T11:11:11.111+01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11.111-01`") as TimestampLiteral
		"2023-03-17T11:11:11.111-01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11.111+01:01`") as TimestampLiteral
		"2023-03-17T11:11:11.111+01:01".assertEquals(parsedTimestamp.value)
		
		parsedTimestamp = parser.parseString("`2023-03-17T11:11:11.111-01:01`") as TimestampLiteral
		"2023-03-17T11:11:11.111-01:01".assertEquals(parsedTimestamp.value)
	}
	
	
	@Test
	def void staticNavigation() {
	    "demo::model::Person".parse
	}
	
	@Test
    def void temporalEllapsedTimeFrom() {
        var parsedDateDiff = parser.parseString("`2001-09-12`!elapsedTimeFrom(`2019-09-12`, demo::measures::Time)") as FunctionedExpression
		"elapsedTimeFrom".assertEquals(parsedDateDiff.getFunctionCall.getFunction.getName)

        var parsedTimestampDiff = parser.parseString("`2001-09-12T12:00:00Z`!elapsedTimeFrom(`2001-09-12T12:00:00+02:00`, demo::measures::Time)") as FunctionedExpression
		"elapsedTimeFrom".assertEquals(parsedTimestampDiff.getFunctionCall.getFunction.getName)

        var parsedTimeDiff = parser.parseString("`12:45`!elapsedTimeFrom(`11:28`, demo::measures::Time)") as FunctionedExpression
		"elapsedTimeFrom".assertEquals(parsedTimeDiff.getFunctionCall.getFunction.getName)

    }
	

	@Test
	def void measuredNumericLiterals() {
		var exp = parser.parseString("10[kg]") as MeasuredLiteral
		BigInteger.valueOf(10).assertEquals(exp.expressionValue)
		"kg".assertEquals(exp.measure)
		
		exp = parser.parseString("1[km/h]") as MeasuredLiteral
		BigInteger.valueOf(1).assertEquals(exp.expressionValue)
		"km/h".assertEquals(exp.measure)

		exp = parser.parseString("0.1[model::Mass#mg]") as MeasuredLiteral
		BigDecimal.valueOf(0.1).assertEquals(exp.expressionValue)
		"model::Mass#mg".assertEquals(exp.measure)
	}

	@Test
	def void navigation() {
	    var simple = parser.parseString("\\a") as NavigationExpression
		var exp = parser.parseString("\\a.b.c") as NavigationExpression
		"a".assertEquals(exp.QName.name)
		"b".assertEquals(exp.features.get(0).name)
		"c".assertEquals(exp.features.get(1).name)
//
//		var nav = "self=>items->product".parse
//		nav = "self=>items.product".parse
//		nav = "self.items->product".parse
//		nav = "self.items.product".parse
//		nav = "(self).items".parse
//		var parenNavigation = "self!selfFun()".parse
//		parenNavigation = "(self!selfFun())".parse
//		parenNavigation = "(self)!selfFun()".parse
//        parenNavigation = "(self.items!itemsFun())".parse
//        parenNavigation = "(self.items)!itemsFun()".parse
//        parenNavigation = "self!selfFun()".parse
//        parenNavigation = "self!selfFun().item".parse
//        parenNavigation = "self!selfFun().item!itemFun()".parse
//        parenNavigation = "(self.elem!elemFun().items)!itemsFun()".parse
//        parenNavigation = "(self.elem!elemFun().items!itemsFun1())!itemsFun2()".parse
//        parenNavigation = "((self!selfFun().elem!elemFun().items)!itemsFun())!itemsFunFun().products!productsFun()".parse
//        print(parenNavigation.asString)
//		var keywordNavigation = "self.items.\\and == self.\\or.\\not".parse() as BinaryOperation
//		"and".assertEquals((keywordNavigation.leftOperand as NavigationExpression).features.get(1).name)
//		"or".assertEquals((keywordNavigation.rightOperand as NavigationExpression).features.get(0).name)
	}

	@Test
	def void relationalOperations() {
		var exp = parser.parseString("a <= 10") as BinaryOperation
		"<=".assertEquals(exp.operator)
		BigInteger.valueOf(10).assertEquals(exp.rightOperand.expressionValue)
		assertTrue(exp.leftOperand instanceof NavigationExpression)
	}

	@Test
	def void parenthesizedOperations() {
		var exp = "self.quantity * self.unitPrice * (1 - self.discount)".parse as BinaryOperation
		"*".assertEquals(exp.operator)
		var left = exp.leftOperand as BinaryOperation
		"self".assertEquals(((left.leftOperand as NavigationExpression).QName as QualifiedName).name)
		"quantity".assertEquals((left.leftOperand as NavigationExpression).features.get(0).name)
		var right = exp.rightOperand as BinaryOperation
		"-".assertEquals(right.operator)
		BigInteger.valueOf(1).assertEquals(right.leftOperand.expressionValue)
		"discount".assertEquals((right.rightOperand as NavigationExpression).features.get(0).name)

		exp = "self.quantity * self.unitPrice + self.unitDiscount * self.quantity".parse as BinaryOperation
		"+".assertEquals(exp.operator)
		"*".assertEquals((exp.leftOperand as BinaryOperation).operator)
		"*".assertEquals((exp.rightOperand as BinaryOperation).operator)
	}

	@Test
	def void functionNavigation() {
		var exp = "demo :: entities::Product!head().weight".parse;
		exp = "self.products!sort(p | p.name)!head().weight".parse;
	}

	@Test
	def void functions() {
		val stringExp = "('hello')!toUpperCase()".parse as FunctionedExpression
		"toUpperCase".assertEquals(stringExp.functionCall.function.name)
		val navigationExp = "self.description!length()".parse as FunctionedExpression
		"length".assertEquals(navigationExp.functionCall.function.name)
		val sumExp = "('hello'!length() + 'world'!length())".parse as BinaryOperation
		"length".assertEquals((sumExp.leftOperand as FunctionedExpression).functionCall.function.name)
//		val concatExp = "self.description!concat(self.copyright, a<12)".parse as NavigationExpression
//		"copyright".assertEquals(
//			(concatExp.features.get(0).functions.get(0).parameters.get(0).expression as NavigationExpression).features.
//				get(0).name)
//		"a".assertEquals(
//			(concatExp.features.get(0).functions.get(0).parameters.get(1).expression as BinaryOperation).leftOperand.
//				asString)
//
//		val unaryExp = "-123.0!round()!radix(16)".parse as UnaryOperation
//		"-".assertEquals(unaryExp.operator)
//		"round".assertEquals(unaryExp.operand.functions.get(0).function.name)
//		"radix".assertEquals(unaryExp.operand.functions.get(1).function.name)
//		BigInteger.valueOf(16).assertEquals(
//			unaryExp.operand.functions.get(1).parameters.get(0).expression.expressionValue)
//
//		val logicalExp = "not self.product!kindof(demo::entities::Category)".parse as UnaryOperation
//		"not".assertEquals(logicalExp.operator)
//		"kindof".assertEquals(
//			(logicalExp.operand as NavigationExpression).features.get(0).functions.get(0).function.name)

		val conditionalFunction = "self.text!length() < 10 ? self.text!fun(param1, param2) : model::Text.item > 0 ? true : false".
			parse
		"(if (< self.text!length() 10) self.text!fun(param1,param2) (if (> model::Text.item 0) true false))".
			assertEquals(conditionalFunction.asString)

		try {
			"self.text!length()<".parse
			fail("Should have thrown exception on invalid syntax")
		} catch (JqlParseException expected) {
		}

	}

	@Test
	def void functionsLambda() {
//		val filterExp = "
//            // multiline expression
//            self.od!
//                filter(
//                    od | od.price > 10
//                )
//        ".parse as NavigationExpression
//		val filterFunction = filterExp.features.get(0).functions.get(0);
//		"filter".assertEquals(filterFunction.function.name)
//		"od".assertEquals(filterFunction.lambdaArgument)
//		val filterLambdaStatement = filterFunction.parameters.get(0).expression as BinaryOperation
//		">".assertEquals(filterLambdaStatement.operator)
//		BigInteger.valueOf(10).assertEquals(filterLambdaStatement.rightOperand.expressionValue)
//		"od".assertEquals((filterLambdaStatement.leftOperand as NavigationExpression).base.name)
//		"price".assertEquals((filterLambdaStatement.leftOperand as NavigationExpression).features.get(0).name)
//
//		val sortExp = "self=>products!sort(elem | elem.unitPrice ASC, elem.name DESC)".parse as NavigationExpression;
//		val sortFunction = sortExp.features.get(0).functions.get(0);
//		"elem".assertEquals(sortFunction.lambdaArgument)
//		"ASC".assertEquals(sortFunction.parameters.get(0).parameterExtension)
//		"elem.unitPrice".assertEquals(sortFunction.parameters.get(0).expression.asString)
//		"DESC".assertEquals(sortFunction.parameters.get(1).parameterExtension)
//		"elem.name".assertEquals(sortFunction.parameters.get(1).expression.asString)
	}

	@Test
	def void typeFunctions() {
		val exp = "self.field!instanceof(Lib::MyType)".parse as FunctionedExpression
		"Lib::MyType".assertEquals(
		    (exp.functionCall.function.parameters.get(0).expression as NavigationExpression).asString)
	}

	@Test
	def void enumLiteral() {
		var exp = "Days#MONDAY".parse as NavigationExpression
		exp.enumValue.assertEquals("MONDAY")
		var nav = "model :: time::Days#MONDAY".parse as NavigationExpression
		"Days".assertEquals(nav.QName.name)
		"model".assertEquals(nav.QName.namespaceElements.get(0));
		"MONDAY".assertEquals(nav.enumValue)
	}

	def JqlExpression parse(CharSequence expressionText) {
		return parser.parseString(expressionText.toString);
	}

	def Object expressionValue(JqlExpression exp) {
		switch exp {
			StringLiteral: exp.value
			IntegerLiteral: exp.value
			DecimalLiteral: exp.value
			DateLiteral: exp.value
			TimestampLiteral: exp.value
			BooleanLiteral: exp.isIsTrue
			MeasuredLiteral: exp.value.expressionValue
			default: null
		}
	}

}
