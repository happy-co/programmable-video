require "yaml"
require "ostruct"
project = OpenStruct.new YAML.load_file("../pubspec.yaml")

Pod::Spec.new do |s|
  s.name             = project.name
  s.version          = project.version
  s.summary          = 'Twilio Programmable Video Flutter package.'
  s.description      = project.description
  s.homepage         = project.homepage
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = 'Twilio Flutter'
  s.source           = { :http => 'https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.static_framework = true

  s.dependency 'Flutter'
  s.dependency 'TwilioVideo', '~> 3.7'

  s.platform = :ios, '11.0'
  s.ios.deployment_target = '11.0'

  # Flutter.framework does not contain a i386 slice. Only x86_64 simulators are supported.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'VALID_ARCHS[sdk=iphonesimulator*]' => 'x86_64' }
  s.swift_version = '5.0'
  s.static_framework = true
end
