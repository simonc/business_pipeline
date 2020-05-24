[![Build Status](https://travis-ci.org/simonc/business_pipeline.svg?branch=master)](https://travis-ci.org/simonc/business_pipeline)

# BusinessPipeline

BusinessPipeline (BP) aim is to help organize your app's logic in a generic way. You define business bricks that you can then plug together to build more eveolved pipelines.

While it was developed with Rails in mind, BP has no dependency upon it and can be used to organize pretty much any Ruby code.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'business_pipeline'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install business_pipeline

## A touch of generic

Let's say you build an API using Rails. Would you agree that most of the time, CRUD actions look pretty much alike?

If your answer is "yes" or "yes but…" BusinessPipeline might be a good fit for you! What if you could write a single process to list resources in a Rails application? Wouldn't it be cool to have a generic code that can adapt to most if not all of your use-cases?

BusinessPipeline has been extracted from applications that did just that. And if you were wondering, no those apps weren't 15-minute blogs 😁.

A typical _index_ process would look like:

```ruby
module Processes
  class Index < ApplicationProcess
    step Steps::FetchAll
    step Steps::Sort
    step Steps::Paginate
  end
end
```

This may look like a trivial example but the power of this simplicity resides in how generic the Steps of your Process are.

We'll start be looking at the basics of working with BusinessPipeline and then move on to how you could leverage its power in a Rails application.

## Basic usage

### Defining a Process

Let's start from the very beginning and define a very focused business process:

```ruby
class UsersIndexProcess
  include BusinessPipeline::Process

  step FetchAllUsers
  step SortUsers
  step PaginateUsers
end
```

### Defining Steps

So far so good. Now let write the Steps that our process uses:

```ruby
class FetchAllUsers
  include BusinessPipeline::Step

  def call
    context.users = User.all
  end
end

class SortUsers
  include BusinessPipeline::Step

  def call
    context.users = context.users.order(context.sort)
  end
end

class PaginateUsers
  include BusinessPipeline::Step

  def call
    context.users = context.user.page(context.page)
  end
end
```

Before we call our process, let's take a look at what we've got.

### Nested processes

A Process is actually a super-Step. This means that a Process can call another Process like any other Step.

```ruby
class UsersIndexProcess
  include BusinessPipeline::Process

  step ::IndexProcess
  step UsersCustomStep
end
```

In some occasions that may be a handy solution but you shouldn't need it most of the time.

### Context

The first thing that you see is that every Step interacts with something called `context`.

This `context` is a _bag-of-data_ that is passed from one Step to another. It can be used as an object, just like we did with `context.users` but you can also use it like a Hash if necessary so here `context[:users]` would also work fine.

```ruby
context.value = 42

context.value    # => 42
context['value'] # => 42
context[:value]  # => 42
```

In our `SortUsers` and `PaginateUsers` Steps we used values from our _context_ that weren't define so far. We'll see how they came to be when looking at how to call a Process.

### Calling a Process

When calling a Process, you can provide an initial _context_ by passing a Hash as argument:

```ruby
UsersIndex.new.perform(page: 1, sort: { created_at: :desc })
```

You can then use this initial _context_ in all your Steps.

A Process returns the modified _context_ at the end of its execution. You can interrogate this _context_ to know if everything went according to plan:

```ruby
result = UsersIndex.new.perform(page: 1, sort: { created_at: :desc })

result.success? # => true
result.failure? # => false
result.users # => …sorted and paginated list of users…
```

## Going generic

So far we've written very narrow focused Processes and Steps but can we rewrite this code so that it becomes generic? Let's see how!

### Process config

Before we get started we need to first take a look at a Process' initialization. It actually accepts a Hash that will act somewhat like `context` but should contain data that _define_ the Process as opposed to `context` that is more related to the _execution_ of the Process.

```ruby
process = IndexProcess.new(collection_name: 'users', model_class: User)
process.perform(page: 1, sort: { created_at: :desc })
```

### Generic Steps

Now that we initialized our Process with a _config_ let's change our Process' code and our Steps.

```ruby
class IndexProcess
  include BusinessPipeline::Process

  step FetchAll
  step Sort
  step Paginate
end
```

So far all we did is remove the `User` part of our class names, now we need to modify the code they contain to be indeed generic.

```ruby
class FetchAll
  include BusinessPipeline::Step

  def call
    collection_name = config.collection_name
    model_class  = config.model_class

    context[collection_name] = model_class.all
  end
end

class Sort
  include BusinessPipeline::Step

  def call
    collection_name = config.collection_name

    context[collection_name] = context[collection_name].order(context.sort)
  end
end

class Paginate
  include BusinessPipeline::Step

  def call
    collection_name = config.collection_name

    context[collection_name] = context[collection_name].page(context.page)
  end
end
```

And done! Not bad actually. We leveraged the information passed to the Process config to be able to reuse our Steps for any type of resource.

## Hooks

More often than not, you will want to implement things that are not quiet part of the business process per se, but are necessary for its good execution nonetheless. That's where _hooks_ come in handy.

_If you're used to Rails, hooks act like `around_action`, `before_action` and `after_action`._

Hooks can be defined on Processes and Steps alike. They accept blocks, method names or classes:

```ruby
class IndexProcess
  include BusinessPipeline::Process

  around do |process, context, config|
    puts "Calling process: #{process.class}"
    puts "Config is: #{config.inspect}"

    puts "Context before call is: #{context.inspect}"

    process.call

    puts "Context after call is: #{context.inspect}"
  end

  before :some_method

  after SomeAwesomeClass

  private def some_method(context, config)

  end
end
```

**Important:** don’t call `process.perform` inside a Hook, it would trigger the hooks and create an infinite loop.

### Hooks execution order

Execution of _around_ hooks will always be the first one. Then the _before_ hooks and to finish the _after_ ones. So writing the following Process

```ruby
class IndexProcess
  include BusinessPipeline::Process

  around do |process|
    puts 'AROUND 1 START'
    process.call
    puts 'AROUND 1 END'
  end

  before { puts 'BEFORE 1' }
  before { puts 'BEFORE 2' }

  around do |process|
    puts 'AROUND 2 START'
    process.call
    puts 'AROUND 2 END'
  end

  after { puts 'AFTER 1' }
  after { puts 'AFTER 2' }
end
```

Would result in the following output:

```
AROUND 1 START
AROUND 2 START
BEFORE 1
BEFORE 2
AFTER 1
AFTER 2
AROUND 2 END
AROUND 1 END
```

### Hooks inheritence

If you inherit from a Process, your new class will inherit the hooks from its parent Process. This is especially useful when you want to centralize specific behaviors across all Processes.

If for instance you wanted to wrap every Process in a transaction (which would be a good idea by the way :wink:), you can define it this way:

```ruby
class TransactionWrapping
  def call(process, context, config)
    ActiveRecord::Base.transaction { process.call }
  end
end

class ApplicationProcess
  include BusinessPipeline::Process

  around TransactionWrapping
end

class IndexProcess < ApplicationProcess
  # …
end
```

Calling your `IndexProcess` will wrap it in a SQL transaction :heart_eyes:.

## Process config configuration

If you go generic all the way, you may end-up with interesting Steps like this:

```ruby
class ExtractAttribute
  include BusinessPipeline::Step

  def call
    attribute_name = config.attribute_name
    expose_as = config.expose_as
    source = config.source

    context[expose_as] = context[source].public_send(attribute_name)
  end
end
```

If for instance you have a `user` in your _context_ and you wanted to expose its `email` attribute as `user_email` the _config_ needed for this to happen would be:

```ruby
{ source: :user, attribute_name: :email, expose_as: :user_email }
```

And the whole Step to translate to

```ruby
class ExtractAttribute
  include BusinessPipeline::Step

  def call
    context.user_email = context.user.email
  end
end
```

Now what happens if you need to call this generic step for several attributes?

Luckily, you can override the Process' _config_ when using a Step and this override will only be active for this specific Step:

```ruby
class SomeUserProcess < ApplicationProcess
  step FindUser

  step ExtractAttribute do
    source :user
    attribute_name :email
    expose_as :user_email
  end

  step ExtractAttribute do
    source :user
    attribute_name :lastname
    expose_as :user_lastname
  end
end
```

At the end of the Process' execution, the context will contain `user_email` and `user_lastname` with the corresponding values.

## Returning early

Very often you may need to stop the execution of a Process. This can happen for two reasons: an error or an early success.

### Errors

If you want to stop the process execution because a situation makes it impossible to continue, you can leverage the `fail!` method.

```ruby
class DataCheck
  include BusinessPipeline::Step

  def call
    context.continue == 'yes' || fail!(error: 'Continue is not set to yes')
  end
end

class CheckingProcess
  include BusinessPipeline::Process

  step DataCheck
end
```

Calling `context.fail!` will stop the execution and merge the information you give it to the _context_.

```ruby
result = CheckingProcess.new.perform(continue: 'no')

result.success? # => false
result.failure? # => true
result.error    # => 'Continue is not set to yes'
```

### Early success

Sometimes, you may want to stop the execution of a Process because of an early success. That's what the `succeed!` method is for.

For instance if you want to have a _find or create_ behavior you could implement it this way:

```ruby
class UserCreationProcess
  include BusinessPipeline::Process

  step FindUser
  step CreateUser
  step SendAccountConfirmationEmail
end

class FindUser
  include BusinessPipeline::Step

  def call
    user = User.find(context.user_id)
    succeed!(user: user) if user
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/simonc/business_pipeline. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BusinessPipeline project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/simonc/business_pipeline/blob/master/CODE_OF_CONDUCT.md).
