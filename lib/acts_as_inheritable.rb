require 'active_record'
require 'acts_as_inheritable/version'

module ActsAsInheritable
  def acts_as_inheritable(options)
    fail ArgumentError, "Hash expected, got #{options.class.name}" unless options.is_a?(Hash)
    fail ArgumentError, 'Empty options' if options[:attributes].blank? && options[:associations].blank?

    class_attribute :inheritable_configuration

    self.inheritable_configuration = {}
    self.inheritable_configuration.merge!(options)

    class_eval do
      def has_parent?
        parent.present?
      end

      # This is an inheritable recursive method that iterates over all of the
      # relations defined on `INHERITABLE_ASSOCIATIONS`. For each instance on
      # each relation it re-creates it.
      def inherit_relations(model_parent = send(:parent), current = self)
        if model_parent && current.class.method_defined?(:inheritable_configuration) && current.class.inheritable_configuration[:associations]
          current.class.inheritable_configuration[:associations].each do |relation|
            parent_relation = model_parent.send(relation)
            relation_instances = parent_relation.respond_to?(:each) ? parent_relation : [parent_relation].compact
            relation_instances.each do |relation_instance|
              inherit_instance(current, model_parent, relation, relation_instance)
            end
          end
        end
      end


      def inherit_instance(current, model_parent, relation, relation_instance)
        new_relation = relation_instance.dup
        belongs_to_associations_names = model_parent.class.reflect_on_all_associations(:belongs_to).collect(&:name)
        saved =
          # Is a `belongs_to` association
          if belongs_to_associations_names.include?(relation.to_sym)
            # You can define your own 'dup' method with a `duplicate!` signature
            new_relation = relation_instance.duplicate! if relation_instance.respond_to?(:duplicate!)
            current.send("#{relation}=", new_relation)
            current.save
          else
            # Is a `has_one | has_many` association
            parent_name = verify_parent_name(new_relation, model_parent)
            new_relation.send("#{parent_name}=", current)
            new_relation.save
          end
        inherit_relations(relation_instance, new_relation) if saved
      end

      def verify_parent_name(new_relation, model_parent)
        parent_name = model_parent.class.to_s.downcase
        return parent_name if new_relation.respond_to?(parent_name)
        many_and_one_associations = model_parent.class.reflect_on_all_associations.select { |a| a.macro != :belongs_to }
        many_and_one_associations.each do |association|
          next unless association.klass.to_s.downcase == new_relation.class.to_s.downcase && association.options.key?(:as)
          as = association.options[:as].to_s
          if new_relation.respond_to?(as) && !new_relation.respond_to?(parent_name)
            parent_name = as
            break
          end
        end
        # Relations has a diffeent name
        unless new_relation.respond_to?(parent_name)
          new_relation.class.reflections.each_key do |reflection|
            next unless new_relation.class.reflections[reflection].class_name == model_parent.class.name
            parent_name = reflection
            break
          end
        end
        parent_name
      end

      def inherit_attributes(force = false, not_force_for = [], method_to_update = nil)
        available_methods = ['update', 'update_columns']
        if has_parent? && self.class.inheritable_configuration[:attributes]
          # Attributes
          self.class.inheritable_configuration[:attributes].each do |attribute|
            current_val = send(attribute)
            if (force && !not_force_for.include?(attribute)) || current_val.blank?
              if method_to_update && available_methods.include?(method_to_update)
                send(method_to_update, {attribute => parent.send(attribute)})
              else
                send("#{attribute}=", parent.send(attribute))
              end
            end
          end
        end
      end

       # This is an inheritable recursive method that iterates over all of the
      # relations defined on `INHERITABLE_ASSOCIATIONS`. For each instance on
      # each relation it re-creates it - this method goes up the chain from child to parent.
      #
      def apply_relations_to_parent(model_parent = send(:parent), current = self)
        if model_parent && current.class.method_defined?(:inheritable_configuration) && current.class.inheritable_configuration[:associations]
          model_parent.class.inheritable_configuration[:associations].each do |relation|
            child_relation = current.send(relation)
            relation_instances = child_relation.respond_to?(:each) ? child_relation : [child_relation].compact
            relation_instances.each do |relation_instance|
              apply_instance_to_parent(current, model_parent, relation, relation_instance)
            end
          end
        end
      end

      def apply_instance_to_parent(current, model_parent, relation, relation_instance)
        new_relation = relation_instance.dup
        belongs_to_associations_names = current.class.reflect_on_all_associations(:belongs_to).collect(&:name)

          # Is a `belongs_to` association
          if belongs_to_associations_names.include?(relation.to_sym)

            # You can define your own 'dup' method with a `duplicate!` signature
            new_relation = relation_instance.duplicate! if relation_instance.respond_to?(:duplicate!)
            model_parent.send("#{relation}=", new_relation)
            saved = model_parent.save
          else
            # Is a `has_one | has_many` association
            child_name = verify_child_name(new_relation, current)
            new_relation.send("#{child_name}=", model_parent)
            saved = new_relation.save
          end
          inherit_relations(relation_instance, new_relation) if saved
      end

      def verify_child_name(new_relation, current)

        child_name = current.class.to_s.downcase
        return child_name if new_relation.respond_to?(child_name)
        many_and_one_associations = current.class.reflect_on_all_associations.select { |a| a.macro != :belongs_to }
        many_and_one_associations.each do |association|
          next unless association.klass.to_s.downcase == new_relation.class.to_s.downcase && association.options.key?(:as)
          as = association.options[:as].to_s
          if new_relation.respond_to?(as) && !new_relation.respond_to?(child_name)
            child_name = as
            break
          end
        end
        # Relations has a different name
        unless new_relation.respond_to?(child_name)
          new_relation.class.reflections.each_key do |reflection|
            next unless new_relation.class.reflections[reflection].class_name == current.class.name
            child_name = reflection
            break
          end
        end
        child_name
      end


      def apply_attributes_to_parent(force = false, not_force_for = [], method_to_update = nil)
        available_methods = ['update', 'update_columns']
        if has_parent? && self.class.inheritable_configuration[:attributes]
          # Attributes
          self.class.inheritable_configuration[:attributes].each do |attribute|
            current_val = parent.send(attribute)
            if (force && !not_force_for.include?(attribute)) || current_val.blank?
              if method_to_update && available_methods.include?(method_to_update)
                parent.send(method_to_update, {attribute => send(attribute)})
              else
                parent.send("#{attribute}=", send(attribute))
              end
            end
          end
        end
      end


    end
  end

  if defined?(ActiveRecord)
    # Extend ActiveRecord's functionality
    ActiveRecord::Base.send :extend, ActsAsInheritable
  end
end
