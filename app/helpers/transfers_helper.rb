module TransfersHelper
  def transfer_file_for_mustache(object)
    {
      id: object.id,
      name: object.name,
      url: file_path(object, format: :js)
    }
  end
end
