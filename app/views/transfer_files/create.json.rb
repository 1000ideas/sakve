if @file.errors.any?
  {errors: @file.errors, context: render_html('failure')}.to_json
else
  @file.to_json(only: [:id, :token], methods: :name)
end
