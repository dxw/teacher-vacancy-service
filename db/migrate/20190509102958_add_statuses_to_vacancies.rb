class AddStatusesToVacancies < ActiveRecord::Migration[5.2]
  def change
    add_column :vacancies, :listed_elsewhere, :integer
    add_column :vacancies, :hired_status, :integer
  end
end
