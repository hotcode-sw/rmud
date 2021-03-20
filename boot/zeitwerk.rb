# frozen_string_literal: true
App.boot(:zeitwerk) do |app|
  start do
    use :bundler

    loader = Zeitwerk::Loader.for_gem
    loader.push_dir(app.config.root)
    loader.log! unless ENV["STAGE"] == "test"
    loader.ignore("./spec")
    loader.ignore("./boot")
    loader.ignore("./db")
    loader.ignore("./gamedriver")
    loader.ignore("./tasks")
    loader.ignore("./vendor")
    loader.ignore("./doc")
    loader.ignore("./boot.rb")
    loader.ignore("./ci.rb")
    loader.ignore("./rmud.rb")
    loader.setup
    loader.eager_load
  end
end