Pod::Spec.new do |spec|
    spec.name     = 'Bridgeos'
    spec.version  = '1.0.0'
    spec.license  = 'MIT'
    spec.summary  = 'Cross-iframe js bridge between native and web for web view in macOS and iOS'
    spec.homepage = 'https://github.com/neutronstarer/bridge_os'
    spec.author   = { 'neutronstarer' => 'neutronstarer@gmail.com' }
    spec.source   = { :git => 'https://github.com/neutronstarer/bridge_os.git',:tag => "#{spec.version}" ,:submodules => true }
    spec.description = 'Cross-iframe js bridge between native and web for web view in macOS and iOS.'
    spec.requires_arc = true
    spec.source_files = 'Bridgeos/*.{h,m}'
    spec.resources = ['Bridgejs/dist/hub.js', 'Bridgejs/dist/hub.min.js']
    spec.ios.frameworks = ['UIKit', 'WebKit']
    spec.ios.deployment_target = '8.0'
    spec.osx.frameworks = ['WebKit']
    spec.osx.deployment_target = '10.11'
end
