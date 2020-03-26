module com.pthariensflame.truffle_dhall {
	exports com.pthariensflame.truffle_dhall;
	exports com.pthariensflame.truffle_dhall.shell;
	exports com.pthariensflame.truffle_dhall.parser;
	exports com.pthariensflame.truffle_dhall.parser.antlr;

	requires org.antlr.v4.runtime;
	requires org.graalvm.truffle;
	requires org.graalvm.sdk;
}
