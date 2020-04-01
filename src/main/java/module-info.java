/**
 * @author Alexander Ronald Altman
 */
module com.pthariensflame.truffle_dhall {
	exports com.pthariensflame.truffle_dhall;
	exports com.pthariensflame.truffle_dhall.evaluation;
	exports com.pthariensflame.truffle_dhall.shell;
	exports com.pthariensflame.truffle_dhall.parser;

	requires transitive kotlin.stdlib.jdk8;
	requires parboiled.java;
	requires transitive org.graalvm.truffle;
	requires org.graalvm.sdk;
}
