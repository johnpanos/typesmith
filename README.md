# Typesmith

Typesmith is a Ruby gem that provides a simple and flexible way to define and validate data structures in your Ruby applications. It's particularly useful for creating type-safe parameter objects and data transfer objects (DTOs) in Rails applications. Additionally, Typesmith includes a powerful generator that can automatically create corresponding TypeScript types for your frontend, ensuring type consistency across your full-stack application.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'typesmith'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install typesmith

## Usage

Typesmith allows you to define structured data objects with type checking. Here's a basic example:

```ruby
class UserParams < Typesmith::Definition
  property :name, type: :string
  property :age, type: :number
  property :email, type: :string
  property :is_active, type: :boolean
end

user_params = UserParams.new(
  name: "John Doe",
  age: 30,
  email: "john@example.com",
  is_active: true
)

puts user_params.name  # Output: John Doe
puts user_params.age   # Output: 30
```

### Nested Structures

You can also define nested structures:

```ruby
class AddressParams < Typesmith::Definition
  property :street, type: :string
  property :city, type: :string
  property :country, type: :string
end

class UserWithAddressParams < Typesmith::Definition
  property :name, type: :string
  property :address, type: AddressParams
end

user_params = UserWithAddressParams.new(
  name: "Jane Doe",
  address: {
    street: "123 Main St",
    city: "Anytown",
    country: "USA"
  }
)

puts user_params.address.city  # Output: Anytown
```

### Optional Properties

You can make properties optional:

```ruby
class OptionalParams < Typesmith::Definition
  property :required_field, type: :string
  property :optional_field, type: :string, optional: true
end

params = OptionalParams.new(required_field: "Hello")
puts params.optional_field  # Output: nil
```

### Array Properties

You can define properties that are arrays of a specific type:

```ruby
class ArrayParams < Typesmith::Definition
  property :tags, type: [:string]
end

params = ArrayParams.new(tags: ["ruby", "rails", "typesmith"])
puts params.tags  # Output: ["ruby", "rails", "typesmith"]
```

### Using in Controllers

Typesmith is particularly useful in Rails controllers for validating and structuring incoming parameters:

```ruby
class UsersController < ApplicationController
  def create
    user_params = UserParams.new(params.require(:user).permit!)
    User.create!(user_params.attributes)
    render json: { status: 'success' }
  rescue Typesmith::BaseProperty::InvalidTypeError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
```

## TypeScript Generator

One of Typesmith's most powerful features is its ability to automatically generate TypeScript type definitions that correspond to your Ruby definitions. This ensures type consistency between your backend and frontend, reducing errors and improving developer productivity.

### Generating TypeScript Types

To generate TypeScript types from your Typesmith definitions, you can use the Typesmith generator. Here's how to use it:

1. Define your Typesmith classes in Ruby:

```ruby
class UserParams < Typesmith::Definition
  property :name, type: :string
  property :age, type: :number
  property :email, type: :string
  property :is_active, type: :boolean
end

class AddressParams < Typesmith::Definition
  property :street, type: :string
  property :city, type: :string
  property :country, type: :string
end

class UserWithAddressParams < Typesmith::Definition
  property :name, type: :string
  property :address, type: AddressParams
end
```

2. Run the Typesmith generator:

```
$ rails generate typesmith:typescript
```

This command will scan your Ruby files for Typesmith definitions and generate corresponding TypeScript types in the `app/javascript/types/__generated__` directory.

### Generated TypeScript Types

For the above Ruby definitions, Typesmith will generate the following TypeScript types:

```typescript
// app/javascript/types/__generated__/user_params.ts
export interface UserParams {
  name: string;
  age: number;
  email: string;
  isActive: boolean;
}

// app/javascript/types/__generated__/address_params.ts
export interface AddressParams {
  street: string;
  city: string;
  country: string;
}

// app/javascript/types/__generated__/user_with_address_params.ts
import { AddressParams } from './address_params';

export interface UserWithAddressParams {
  name: string;
  address: AddressParams;
}
```

### Using Generated Types in Frontend

You can now use these generated types in your TypeScript frontend code:

```typescript
import { UserWithAddressParams } from '../types/__generated__/user_with_address_params';

const user: UserWithAddressParams = {
  name: "Jane Doe",
  address: {
    street: "123 Main St",
    city: "Anytown",
    country: "USA"
  }
};

// TypeScript will enforce type checking based on the generated definitions
```

### Keeping Types in Sync

It's recommended to run the Typesmith generator as part of your continuous integration (CI) process to ensure that your TypeScript types are always in sync with your Ruby definitions. You can add a step in your CI pipeline to run the generator and fail the build if there are any uncommitted changes to the generated files.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/johnpanos/typesmith. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/johnpanos/typesmith/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Typesmith project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/johnpanos/typesmith/blob/main/CODE_OF_CONDUCT.md).
