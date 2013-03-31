SUMMARY
-------

This gem adds robokassa support to your app.

Robokassa is payment system, that provides a single simple interface for payment systems popular in Russia.
If you have customers in Russia you can use the gem.

The first thing about this gem, is that it was oribinally desgned for spree commerce. So keep it im mind.

Данный джем является форком джема: https://github.com/shaggyone/robokassa

Using the Gem
-------------

Add the following line to your app Gemfile

    gem 'robokassa'

Update your bundle

    bundle install

```ruby
config/initializers/robokassa.rb:

ROBOKASSA_SETTINGS = {
  :test_mode => true,
  :login => 'LOGIN',
  :password1 => 'PASSWORD1',
  :password2 => 'PASSWORD2'
}

$robokassa = Robokassa::Interface.new(ROBOKASSA_SETTINGS)

module Robokassa
  class Interface
    def notify_implementation(invoice_id, *args); end

    class << self
      def get_options_by_notification_key(key)
        ROBOKASSA_SETTINGS
      end

      def success_implementation(invoice_id, *args)
        payment = Payment.find_by_id(invoice_id)
        payment.to_success!
      end

      def fail_implementation(invoice_id, *args)
        payment = Payment.find_by_id(invoice_id)
        payment.to_fail!
      end
    end
  end
end

routes.rb:

...
controller :robokassa do
  get "robokassa/:notification_key/notify" => :notify, :as => :robokassa_notification
  get "robokassa/success" => :success, :as => :robokassa_on_success
  get "robokassa/fail" => :fail, :as => :robokassa_on_fail
end
...

class Dashboard::PaymentsController < Dashboard::ApplicationController
  ...
  def create
    @payment = current_user.payments.create!(:amount => params[:payment][:amount])
    pay_url = $robokassa.init_payment_url(
      @payment.id, @payment.amount, "Платеж № #{@payment.id}",
      '', 'ru', current_user.email, {}
    )
    redirect_to pay_url
  end
  ...

class Payment < ActiveRecord::Base
  include AASM

  validates_presence_of :user_id, :amount
  attr_accessible :amount
  belongs_to :user

  default_scope order("id desc")

  aasm do
    state :new, :initial => true
    state :success
    state :fail

    event :to_success, :after => :give_money! do
      transitions :to => :success
    end

    event :to_fail do
      transitions :to => :fail
    end
  end

  def state
    self.aasm_state
  end

  def give_money!
    self.user.give_money!(self.amount)
  end

  def printable_amount
    "#{self.amount.to_s} руб."
  end
end

class User < ActiveRecord::Base
  ...
  def give_money!(amount)
    sql = "update users set balance='#{self.balance + amount.to_f}' where id='#{self.id}'"
    connection.update(sql)
  end
  ...

dashboarb/payments/_form.html.erb:

<%= semantic_form_for [:dashboard, @payment] do |f| %>
  <%= f.error_messages %>
  <%= f.input :amount %>
  <%= actions_for f, "Пополнить" %>
<% end %>

app/controllers/robokassa.rb:

# coding: utf-8
class RobokassaController < Robokassa::Controller
  def success
    super
    @payment = Payment.find_by_id(params[:InvId])
    if @payment
      redirect_to dashboard_payment_path(@payment),
        :notice => "Ваш платеж на сумму #{@payment.amount.to_s} руб. успешно принят. Спасибо!"
    else
      redirect_to new_dashboard_payment_path,
        :error => "Не могу найти платеж по данному идентификатору"
    end
  end

  def fail
    super
    redirect_to dashboard_payments_path,
      :error => "Во время принятия платежа возникла ошибка. Мы скоро разберемся!"
  end
end

```

In Robokassa account settings set:

    Result URL: http://example.com/robokassa/default/notify
    Success URL: http://example.com/robokassa/success
    Fail URL: http://example.com/robokassa/fail

Testing
-----
In console:

Clone gem
```bash
git clone git://github.com/shaggyone/robokassa.git
```

Install gems and generate a dummy application (It'll be ignored by git):
```bash
cd robokassa
bundle install
bundle exec combust
```

Run specs:
```bash
rake spec
```

Generate a dummy test application

Plans
-----

I plan to add generators for views
