/**
 * @author Alexander Ronald Altman
 */
module com.pthariensflame.truffle_dhall {
//	exports com.pthariensflame.truffle_dhall;
//	exports com.pthariensflame.truffle_dhall.evaluation;
//	exports com.pthariensflame.truffle_dhall.shell;
//	exports com.pthariensflame.truffle_dhall.parser;
	exports com.pthariensflame.truffle_dhall.ast;

	requires transitive kotlin.stdlib.jdk8;
	requires funcj.parser;
	requires transitive org.graalvm.truffle;
	requires org.graalvm.sdk;
}
