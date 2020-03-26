/**
 * @author Alexander Ronald Altman
 */
module com.pthariensflame.truffle_dhall {
	exports com.pthariensflame.truffle_dhall;
	exports com.pthariensflame.truffle_dhall.evaluation;
	exports com.pthariensflame.truffle_dhall.shell;
	exports com.pthariensflame.truffle_dhall.parser;

	//requires antlr4.runtime;
	requires org.graalvm.truffle;
	requires org.graalvm.sdk;
	requires com.pthariensflame.truffle_dhall.parser.antlr;
}
