test_name "puppet module list (with missing dependencies)"

teardown do
  on master, "rm -rf #{master['distmoduledir']}/thelock"
  on master, "rm -rf #{master['distmoduledir']}/appleseed"
  on master, "rm -rf #{master['sitemoduledir']}/crick"
end

step "Setup"
apply_manifest_on master, <<-PP
file {
  [
    '#{master['distmoduledir']}/appleseed',
    '#{master['distmoduledir']}/thelock',
    '#{master['sitemoduledir']}/crick',
  ]: ensure => directory,
     recurse => true,
     purge => true,
     force => true;
  '#{master['distmoduledir']}/appleseed/metadata.json':
    content => '{
      "name": "jimmy/appleseed",
      "version": "1.1.0",
      "source": "",
      "author": "jimmy",
      "license": "MIT",
      "dependencies": [
        { "name": "jimmy/crakorn", "version_requirement": "0.4.0" }
      ]
    }';
  '#{master['distmoduledir']}/thelock/metadata.json':
    content => '{
      "name": "jimmy/thelock",
      "version": "1.0.0",
      "source": "",
      "author": "jimmy",
      "license": "MIT",
      "dependencies": [
        { "name": "jimmy/appleseed", "version_requirement": "1.x" },
        { "name": "jimmy/sprinkles", "version_requirement": "2.x" }
      ]
    }';
  '#{master['sitemoduledir']}/crick/metadata.json':
    content => '{
      "name": "jimmy/crick",
      "version": "1.0.1",
      "source": "",
      "author": "jimmy",
      "license": "MIT",
      "dependencies": [
        { "name": "jimmy/crakorn", "version_requirement": "0.4.x" }
      ]
    }';
}
PP

on master, "[ -d #{master['distmoduledir']}/appleseed ]"
on master, "[ -d #{master['distmoduledir']}/thelock ]"
on master, "[ -d #{master['sitemoduledir']}/crick ]"

step "List the installed modules"
on master, puppet('module list') do
  assert_equal <<-STDERR, stderr
\e[1;31mWarning: Missing dependency 'jimmy-crakorn':
  'jimmy-appleseed' (v1.1.0) requires 'jimmy-crakorn' (v0.4.0)
  'jimmy-crick' (v1.0.1) requires 'jimmy-crakorn' (v0.4.x)\e[0m
\e[1;31mWarning: Missing dependency 'jimmy-sprinkles':
  'jimmy-thelock' (v1.0.0) requires 'jimmy-sprinkles' (v2.x)\e[0m
STDERR
  assert_equal <<-STDOUT, stdout
#{master['distmoduledir']}
├── jimmy-appleseed (\e[0;36mv1.1.0\e[0m)
└── jimmy-thelock (\e[0;36mv1.0.0\e[0m)
#{master['sitemoduledir']}
└── jimmy-crick (\e[0;36mv1.0.1\e[0m)
STDOUT
end

step "List the installed modules as a dependency tree"
on master, puppet('module list --tree') do
  assert_equal <<-STDERR, stderr
\e[1;31mWarning: Missing dependency 'jimmy-crakorn':
  'jimmy-appleseed' (v1.1.0) requires 'jimmy-crakorn' (v0.4.0)
  'jimmy-crick' (v1.0.1) requires 'jimmy-crakorn' (v0.4.x)\e[0m
\e[1;31mWarning: Missing dependency 'jimmy-sprinkles':
  'jimmy-thelock' (v1.0.0) requires 'jimmy-sprinkles' (v2.x)\e[0m
STDERR
  assert_equal <<-STDOUT, stdout
#{master['distmoduledir']}
└─┬ jimmy-thelock (\e[0;36mv1.0.0\e[0m)
  ├── \e[0;41mUNMET DEPENDENCY\e[0m jimmy-sprinkles (\e[0;36mv2.x\e[0m)
  └─┬ jimmy-appleseed (\e[0;36mv1.1.0\e[0m)
    └── \e[0;41mUNMET DEPENDENCY\e[0m jimmy-crakorn (\e[0;36mv0.4.0\e[0m)
#{master['sitemoduledir']}
└─┬ jimmy-crick (\e[0;36mv1.0.1\e[0m)
  └── \e[0;41mUNMET DEPENDENCY\e[0m jimmy-crakorn (\e[0;36mv0.4.x\e[0m)
STDOUT
end
