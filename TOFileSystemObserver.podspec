Pod::Spec.new do |s|
  s.name     = 'TOFileSystemObserver'
  s.version  = '0.0.3'
  s.license  =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary  = 'A bullet-proof mechanism for detecting any changes made to the contents of a folder in iOS & iPadOS.'
  s.homepage = 'https://github.com/TimOliver/TOFileSystemObserver'
  s.author   = 'Tim Oliver'
  s.source   = { :git => 'https://github.com/TimOliver/TOFileSystemObserver.git', :tag => s.version }
  s.platforms = { :ios => "8.0", :osx => "10.12" }
  s.source_files = 'TOFileSystemObserver/**/*.{h,m}'
  s.osx.exclude_files = 'TOFileSystemObserver/Utilities/TOFileSystemObserver+UIKit.h'
  s.ios.exclude_files = ['TOFileSystemObserver/Utilities/TOFileSystemObserver+AppKit.h','TOFileSystemObserver/Categories/NSIndexPath+AppKitAdditions.{h,m}']
  s.requires_arc = true
end