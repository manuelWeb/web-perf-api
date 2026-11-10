-- Up Migration
CREATE TABLE products (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  sku text NOT NULL UNIQUE,
  name text NOT NULL CHECK (length(trim(name)) > 0),
  price_cents integer NOT NULL CHECK (price_cents >= 0)
);

CREATE TABLE users (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  display_name text NOT NULL CHECK (length(trim(display_name)) > 0)
);

-- Down Migration
DROP TABLE users;
DROP TABLE products;
