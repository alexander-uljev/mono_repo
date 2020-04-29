# MonoRepo

The MonoRepo library offers you a pattern of developing your applications in a
mono repository and a set of functions to do it easily.

With mono repository pattern your umbrella applications can nest other mono or
umbrella applications to build an application tree of any structure. This
pattern is useful when you need to create multiple related applications which
must be decoupled, but still relate on each other. Just create your applications
in *apps* directory, create umbrella applications in other umbrella's *apps*,
build hybrids of umbrella-mono applications.

By following this pattern and using `MonoRepo` you will keep your project
well-structured and `MonoRepo.Release` will give you a hand with defining,
configuring and releasing your application.

For more information, please refer to the library's documentation.

## Installation

The package is [available at Hex](https://hex.pm/docs/publish), and can be installed by adding `mono_repo`
to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mono_repo, "~> 0.1.0"}
  ]
end
```

### License

MIT

### Metadata

-author:       Alexander Ulyev
-email:        aleksandr.uljev@yandex.ru
-release date: 29.04.2020
