require_dependency 'issue'

# Patches Redmine's Issues dynamically.  Adds a relationship 
# Issue +belongs_to+ to Deliverable
module IssuePatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)

    base.send(:include, InstanceMethods)

    # Same as typing in the class 
    base.class_eval do
      unloadable # Send unloadable so it will not be unloaded in development
      #before_save :check_identifier
      before_validation :check_identifier
      after_save :check_chapter
    end

  end
  
  module ClassMethods
  end
  
  module InstanceMethods
    @@cfdoccount = IssueCustomField.find_by_name('RqIdCounter')    
    @@cfdocprefix = ProjectCustomField.find_by_name('RqPrefix')  
    @@cfisschapter = IssueCustomField.find_by_name('RqChapter')  
		@@rqdoctrck = Tracker.find_by_name('ReqDoc')
    
    def document
      ret = nil
      if self.tracker == @@rqdoctrck then
        print "Este doc es un documento"
        ret = self 
      else
        print "Este doc no es un documento"
        # not do found yet
        ret = self.parent
        if ret != nil then
          print "retornamos el documento padre"
          ret = ret.document
        end
      end
      return ret
    end
    
    def check_identifier
      # AUTO SUBJECT
      if self.subject == "" or self.subject == nil then
        print "vamos a crear un subject"
        if @@cfdoccount != nil then
          print "tenemos el custom field del contaddor"
          thisdocument = self.document
          if thisdocument != nil then
            print "Tenemos un documento"
            cfdoccount = self.document.custom_values.find_by_custom_field_id(@@cfdoccount.id)
            if cfdoccount != nil then
              print "vamos a buscar un prefijo"
              if @@cfdocprefix != nil then
                cfdocprefix = self.project.custom_values.find_by_custom_field_id(@@cfdocprefix.id)
                print "tenemos un prefijo"
                if cfdocprefix != nil then
                  self.subject = cfdocprefix.value+"-"+format('%04d', cfdoccount.value)
                  print "el subject me queda "+self.subject
                  cfdoccount.value = (cfdoccount.value.to_i+1)
                  cfdoccount.save
                  print "guardado quedo"
                end
              end
            end
            return true 
          else
          end
        end
      end
      return false 
    end

    def check_chapter
      # AUTO CHAPTER
      if @@cfisschapter != nil then
        cfisschapter = self.custom_values.find_by_custom_field_id(@@cfisschapter.id)
        if cfisschapter == nil then
          cfisschapter = CustomValue.new
          cfisschapter.custom_field = @@cfisschapter
          cfisschapter.customized = self
          cfisschapter.value = nil
        end
        if cfisschapter.value == "" or cfisschapter.value == nil then
          if self.parent != nil then
            cfparentiffchapter = self.parent.custom_values.find_by_custom_field_id(@@cfisschapter.id)
            if cfparentiffchapter == nil then
              self.parent.save
            end
            cfisschapter.value = cfparentiffchapter.value+"z."
          else
            if @@cfdocprefix != nil then
              cfprjprefix = self.project.custom_values.find_by_custom_field_id(@@cfdocprefix.id)
            end
            cfisschapter.value = cfprjprefix.value+"-z.1."
          end
          cfisschapter.save
        end
      end
      return true 
    end
  end    
end
# Add module to Issue
Issue.send(:include, IssuePatch)


