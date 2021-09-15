# programmable_video_platform_interface

A common platform interface for the [`programmable_video`][1] plugin.

This interface allows platform-specific implementations of the `programmable_video`
plugin, as well as the plugin itself, to ensure they are supporting the
same interface.

# Usage

To implement a new platform-specific implementation of `programmable_video`, extend
[`ProgrammableVideoPlatform`][2] with an implementation that performs the
platform-specific behavior, and when you register your plugin, set the default
`ProgrammableVideoPlatform` by calling
`ProgrammableVideoPlatform.instance = MyPlatformProgrammableVideo()`.

# Note on breaking changes

Strongly prefer non-breaking changes (such as adding a method to the interface)
over breaking changes for this package.

See https://flutter.dev/go/platform-interface-breaking-changes for a discussion
on why a less-clean interface is preferable to a breaking change.

[1]: https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video
[2]: https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/programmable_video_platform_interface/lib/src/programmable_video_platform_interface.dart

# Development and Contributing

Interested in contributing? We love merge requests! See the [Contribution](https://gitlab.com/twilio-flutter/programmable-video/-/tree/master/CONTRIBUTING.md) guidelines.

# Contributions By

[![HomeX - Home Repairs Made Easy](https://homex.com/static/brand/homex-logo-green.svg)](https://homex.com)
