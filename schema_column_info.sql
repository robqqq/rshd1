create or replace procedure schema_column_info(col text, sch text) as $$
declare
    attr_count int;
    info cursor for
        select attr.attname,
               attr.atttypid,
               attr.atttypmod,
               cls.relname,
               des.description,
               string_agg(pg_get_constraintdef(con.oid), RPAD(E'\n.', 39, ' ')) as constr,
               string_agg(idx.indexrelid::regclass::text, RPAD(E'\n.', 39, ' ')) as idx_name
        from pg_catalog.pg_attribute attr
            join pg_catalog.pg_class cls on attr.attrelid = cls.oid
            join pg_catalog.pg_namespace spc on cls.relnamespace = spc.oid
            left join pg_catalog.pg_constraint con on con.conrelid = cls.oid and attr.attnum = any(con.conkey)
            left join pg_catalog.pg_description des on des.objoid = attr.attrelid and des.objsubid = attr.attnum
            left join pg_catalog.pg_index idx on attr.attrelid = idx.indrelid and attr.attnum = any(idx.indkey)
        where spc.nspname = sch and attr.attname = col
        group by attr.attname, attr.atttypid, attr.atttypmod, cls.relname, des.description;
begin
    select count(distinct nspname)
    into attr_count
    from pg_catalog.pg_attribute attr
        join pg_catalog.pg_class cls on attr.attrelid = cls.oid
        join pg_catalog.pg_namespace spc on cls.relnamespace = spc.OID
    where spc.nspname = sch and attr.attname = col;
    if attr_count < 1 then
        raise exception 'Не найдено ни одного столбца с именем "%" в схеме "%"', col, sch;
    else
        raise notice 'No  Имя столбца  Имя таблицы  Атрибуты';
        raise notice '--  -----------  -----------  --------';
        attr_count := 1;
        for att in info
        loop
            raise notice '% % % Type  : %', rpad(attr_count::text, 3, ' '), rpad(att.attname, 12, ' '), rpad(att.relname, 12, ' '), format_type(att.atttypid, att.atttypmod);
            raise notice '.% Constr: %', rpad('', 28, ' '), case when att.constr is not null then E'CONSTRAINT\n' || RPAD('.', 38, ' ') || att.constr else '' end;
            raise notice '.% Commen: %', rpad('', 28, ' '), case when att.description is not null then att.description else '' end;
            raise notice '.% Index : %', rpad('', 28, ' '), case when att.idx_name is not null then att.idx_name else '' end;
            attr_count := attr_count + 1;
        end loop;
    end if;
end
$$ language plpgsql