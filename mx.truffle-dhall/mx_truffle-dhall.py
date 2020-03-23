import mx
import mx_subst
import mx_sdk

SUITE = mx.suite('truffle-dhall')

def _get_src_dir(projectname):
  for suite in mx.suites():
    for p in suite.projects:
      if p.name == projectname:
        if len(p.source_dirs()) > 0:
          return p.source_dirs()[0]
        else:
          return p.dir
        mx.abort("Could not find src dir for project %s" % projectname)

mx_subst.path_substitutions.register_with_arg('src_dir', _get_src_dir)

mx_sdk.register_graalvm_component(mx_sdk.GraalVmLanguage(
    suite=SUITE,
    name='Truffle-Dhall',
    short_name='dhl',
    dir_name='truffle-dhall',
    standalone_dir_name='truffle-dhall-<version>-<graalvm_os>-<arch>',
    license_files=[],
    third_party_license_files=[],
    dependencies=['Truffle'],
    standalone_dependencies={},
    truffle_jars=[
        'truffle-dhall:TRUFFLE-DHALL',
    ],
    support_distributions=[],
    launcher_configs=[
        mx_sdk.LanguageLauncherConfig(
            destination='bin/<exe:truffle-dhall>',
            jar_distributions=['truffle-dhall:TRUFFLE-DHALL-LAUNCHER'],
            main_class='com.pthariensflame.truffle-dhall.shell.TruffleDhallMain',
            build_args=[],
            language='dhall',
        )
    ],
))
