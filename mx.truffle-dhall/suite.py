suite = {
  "name" : "truffle-dhall",
  "mxversion" : "5.256.3",
  "groupId" : "org.pthariensflame.truffle-dhall",
  "url" : "https://github.com/pthariensflame/truffle-dhall",
  "developer" : {
    "name" : "GraalVM Development",
    "email" : "graalvm-dev@oss.oracle.com",
    "organization" : "Oracle Corporation",
    "organizationUrl" : "http://www.graalvm.org/",
  },
  "defaultLicense" : "BSD-3",
  "scm" : {
    "url" : "https://github.com/pthariensflame/truffle-dhall",
    "read" : "https://github.com/pthariensflame/truffle-dhall.git",
    "write" : "git@github.com:pthariensflame/truffle-dhall.git",
  },
  "imports" : {
    "suites": [
    ]
  },
  "libraries" : {
    "JLINE" : {
      "sha1" : "d3c97ca029afb0db85727bee53cb5a3e1de73598",
      "maven" : {
        "groupId" : "org.jline",
        "artifactId" : "jline",
        "version" : "3.14.0",
      }
    },
    "ANTLR4": {
      "sha1" : "7fe453b678b71c87c6677cef26f6b0cd96b26586",
      "maven" : {
        "groupId" : "org.antlr",
        "artifactId" : "antlr4-runtime",
        "version" : "4.8",
      }
    },
    "ANTLR4_COMPLETE": {
      "urls": ["https://www.antlr.org/download/antlr-4.8-complete.jar"],
      "sha1": "a675db077abf60d720f80f968602be763131820c",
    },
  },
  "projects" : {
  },
}
