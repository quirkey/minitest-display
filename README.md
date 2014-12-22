# minitest-display

MiniTest::Display is a module that monkey patches a lot of the MiniTest::Unit internals to allow for configurable display options.
You want color?! You want Suite name printouts?!?! You want fried eggs?! Too bad.

I was messing with [leftright](https://github.com/jordi/leftright) (which is awesome btw) and trying to get it to work well with 1.9 but its all tied up in Test::Unit.
MiniTest is much much simpler, and its patch points are easy to override and much less scary. Beyond that, MiniTest is also faster and has some neat benefits over test/unit (like benchmark assertions, etc). So, off we went. 

The goal is to be as configurable as possible with some nice defaults. My problem with most test enhancers is that they monkey patch blindly with very little openness and room for configuration. MiniTest::Display should allow for an infinite number (evenutally) of test display enhancements.

Needless to say, it's a work in progress.

## Requirements

Requires Ruby > 1.9

For Minitest 4 use minitest-display ~> 0.2
For Minitest 5 use minitest-display >= 0.3.0

## Usage

Install minitest and minitest display:

      gem install minitest minitest-display

In your test suite/test_helper, require and configure mini test/display:

      require 'minitest/autorun'
      require 'minitest/display'

      MiniTest::Display.options = {
        suite_names: true,
        color: true,
        print: {
          success: "OK\n",
          failure: "EPIC FAIL\n",
          error: "ERRRRRRR\n"
        }
      }

That suite will look pretty funny. 

The default output looks something like:

![Term](http://www.quirkey.com/skitch/Terminal_%E2%80%94_bash_%E2%80%94_120%C3%9730-20110327-210856.jpg)

For all current available options [see the code](https://github.com/quirkey/minitest-display/blob/master/lib/minitest/display.rb#L25)

## Contributing to minitest-display
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 Aaron Quint. See LICENSE.txt for
further details.

