#
# Be sure to run `pod lib lint MagistralSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'MagistralSwift'
s.version          = '0.7.3'
s.summary          = 'Magistral Swift SDK'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

s.description      = 'Swift 3 SDK for Magistral Data Streaming Service'

s.homepage         = 'https://github.com/magistral-io/MagistralSwift'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'roman.kurpatov' => 'roman.kurpatov@magistral.io' }
s.source           = { :git => 'https://github.com/magistral-io/MagistralSwift.git', :tag => '0.7.3' }

s.ios.deployment_target = '9.0'

s.source_files = 'MagistralSwift/**/*'

# s.resource_bundles = {
#   'MagistralSwift' => ['MagistralSwift/Assets/*.png']
# }

# s.public_header_files = 'Pod/Classes/**/*.h'

s.dependency 'Alamofire', '~> 4.4.0'
s.dependency 'SwiftMQTT'
s.dependency 'CryptoSwift', '~> 0.6.6'
s.dependency 'SwiftyJSON', '~> 3.1.4'
end
