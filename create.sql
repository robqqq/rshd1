CREATE OR REPLACE FUNCTION schema_columns_info(column text, schema text)
RETURNS VOID AS 
$$
    DECLARE
        new_tab CURSOR FOR (
            SELECT attr.attname, cls.relname, typ.typname, des.description, idx.indexrelid::regclass as idxname 
            FROM pg_attribute attr
                JOIN pg_class cls on attr.attrelid = cls.oid
                JOIN pg_namespace spc on cls.relnamespace = spc.oid
                JOIN pg_type typ on attr.atttypid = typ.oid
                LEFT JOIN pg_description des on des.objoid = attr.attrelid and des.objsubid = attr.attnum
                LEFT JOIN pg_index idx on attr.attrelid = idx.indrelid and attr.attnum = any(idx.indkey)
            WHERE spc.nspname = schema and attr.attname = column
        );
        attr_count int;
    BEGIN
        SELECT COUNT(DISTINCT nspname) 
        INTO attr_count 
        FROM pg_attribute attr 
            JOIN pg_class cls on attr.attrelid = cls.oid
            JOIN pg_namespace spc on cls.relnamespace = spc.oid
        WHERE spc.nspname = schema and attr.attname = column;

        IF attr_count < 1 THEN
            RAISE EXCEPTION 'Не найдено ни одного столбца с именем "%" в схеме "%"', column, schema;
        ELSE
            RAISE NOTICE 'No  Имя столбца  Имя таблицы  Атрибуты'
            RAISE NOTICE '--  -----------  -----------  --------'

            i int = 1;
            FOR col in new_tab
            LOOP
                RAISE NOTICE ''
