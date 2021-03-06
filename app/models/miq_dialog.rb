class MiqDialog < ActiveRecord::Base
  validates_presence_of   :name, :description
  validates_uniqueness_of :name, :scope => :dialog_type, :case_sensitive => false

  DIALOG_DIR = Rails.root.join("product/dialogs/miq_dialogs")

  DIALOG_TYPES = [
    ["VM Provision",                "MiqProvisionWorkflow"],
    ["Configured System Provision", "MiqProvisionConfiguredSystemWorkflow"],
    ["Host Provision",              "MiqHostProvisionWorkflow"],
    ["VM Migrate",                  "VmMigrateWorkflow"],
  ]

  serialize :content

  include ReportableMixin

  def self.seed
    MiqRegion.my_region.lock do
      self.sync_from_dir
    end
  end

  def self.sync_from_dir
    Dir.glob(File.join(DIALOG_DIR, "*.yaml")).each {|f| self.sync_from_file(f)}
  end

  def self.sync_from_file(filename)
    item = YAML.load_file(filename)

    item[:filename] = filename.sub(DIALOG_DIR.to_path + "/", "")
    item[:file_mtime] = File.mtime(filename).utc
    item[:default] = true

    rec = self.find_by_name_and_filename(item[:name], item[:filename])

    if rec
      if rec.filename && (rec.file_mtime.nil? || rec.file_mtime.utc < item[:file_mtime])
        _log.info("[#{rec.name}] file has been updated on disk, synchronizing with model")
        rec.update_attributes(item)
        rec.save
      end
    else
      _log.info("[#{item[:name]}] file has been added to disk, adding to model")
      self.create(item)
    end
  end

end
