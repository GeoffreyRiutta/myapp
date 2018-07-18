class CreateGeoResults < ActiveRecord::Migration[5.2]
  def change
    create_table :geo_results do |t|
      t.string :search
      t.binary :source
      t.binary :result

      t.timestamps
    end
  end
end
