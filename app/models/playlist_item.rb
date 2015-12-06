class PlaylistItem
attr_accessor :image, :file, :title, :clip_name, :md5_sum, :id
def persisted?
	false
end	

end