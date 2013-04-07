# coding: utf-8
Robokassa::Engine.routes.draw do
  controller :robokassa do
    get "/:notification_key/notify" => :notify, :as => :robokassa_notification
    get "/success" => :success, :as => :robokassa_on_success
    get "/fail" => :fail, :as => :robokassa_on_fail
  end
end
