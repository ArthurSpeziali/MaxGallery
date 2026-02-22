defmodule MaxGallery.Repo.Migrations.AddSecurityConstraints do
  use Ecto.Migration

  def up do
    # Create function to validate group ownership for cyphers
    execute """
    CREATE OR REPLACE FUNCTION validate_cypher_group_ownership()
    RETURNS TRIGGER AS $$
    BEGIN
      IF NEW.group_id IS NOT NULL THEN
        IF NOT EXISTS (
          SELECT 1 FROM groups 
          WHERE groups.id = NEW.group_id 
          AND groups.user_id = NEW.user_id
        ) THEN
          RAISE EXCEPTION 'Cypher can only reference groups from the same user';
        END IF;
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Create function to validate group parent ownership
    execute """
    CREATE OR REPLACE FUNCTION validate_group_parent_ownership()
    RETURNS TRIGGER AS $$
    BEGIN
      IF NEW.group_id IS NOT NULL THEN
        IF NOT EXISTS (
          SELECT 1 FROM groups parent 
          WHERE parent.id = NEW.group_id 
          AND parent.user_id = NEW.user_id
        ) THEN
          RAISE EXCEPTION 'Group can only reference parent groups from the same user';
        END IF;
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """

    # Create triggers
    execute """
    CREATE TRIGGER cypher_group_ownership_trigger
      BEFORE INSERT OR UPDATE ON cyphers
      FOR EACH ROW
      EXECUTE FUNCTION validate_cypher_group_ownership();
    """

    execute """
    CREATE TRIGGER group_parent_ownership_trigger
      BEFORE INSERT OR UPDATE ON groups
      FOR EACH ROW
      EXECUTE FUNCTION validate_group_parent_ownership();
    """

    # Add unique constraint on (user_id, file) to prevent ID collision within user scope
    create unique_index("groups", [:user_id, :file], name: "groups_user_file_unique")
    create unique_index("cyphers", [:user_id, :file], name: "cyphers_user_file_unique")
  end

  def down do
    # Remove triggers
    execute "DROP TRIGGER IF EXISTS cypher_group_ownership_trigger ON cyphers;"
    execute "DROP TRIGGER IF EXISTS group_parent_ownership_trigger ON groups;"
    
    # Remove functions
    execute "DROP FUNCTION IF EXISTS validate_cypher_group_ownership();"
    execute "DROP FUNCTION IF EXISTS validate_group_parent_ownership();"
    
    # Remove unique indexes
    drop_if_exists index("groups", [:user_id, :file], name: "groups_user_file_unique")
    drop_if_exists index("cyphers", [:user_id, :file], name: "cyphers_user_file_unique")
  end
end
