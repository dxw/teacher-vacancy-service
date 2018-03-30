module AuthHelpers
  def stub_authenticate(return_value: true)
    allow_any_instance_of(ApplicationController)
      .to receive(:authenticate?)
      .and_return(return_value)
  end

  def stub_access_basic_auth_env(env_field_for_username: :http_user,
                                 env_field_for_password: :http_pass,
                                 env_value_for_username: 'foo',
                                 env_value_for_password: 'bar')
    fake_env = double.as_null_object
    allow(Figaro).to receive(:env).and_return(fake_env)
    allow(fake_env).to receive(env_field_for_username.to_sym).and_return(env_value_for_username)
    allow(fake_env).to receive(env_field_for_password.to_sym).and_return(env_value_for_password)
  end
end

RSpec.shared_context 'when authenticated as a member of hiring staff' do |credentials|
  let(:username) { credentials[:username] || 'foo' }
  let(:password) { credentials[:password] || 'bar' }

  background do
    stub_basic_auth_env if credentials[:stub_basic_auth_env] == true
    authenticate(username, password)
  end

  def stub_basic_auth_env
    stub_access_basic_auth_env(env_field_for_username: :hiring_staff_http_user,
                               env_field_for_password: :hiring_staff_http_pass,
                               env_value_for_username: username,
                               env_value_for_password: password)
  end

  def authenticate(username, password)
    page.driver.browser.basic_authorize(username, password)
  end
end