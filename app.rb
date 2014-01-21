require 'pry'
require 'sinatra'
require 'sinatra/reloader'
require 'pg'

def dbname
  "storeadminsite"
end

def with_db
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  yield c
  c.close
end

get '/' do
  erb :index
end

# The Products machinery:

# Get the index of products
get '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the products table.
  @products = c.exec_params("SELECT * FROM products;")
  c.close
  erb :products
end




# Get the index of categories
get '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Get all rows from the products table.
  @categories = c.exec_params("SELECT * FROM categories;")
  c.close
  erb :categories
end



# Get the form for creating a new product
get '/products/new' do
  erb :new_product
end

# Get the form for creating a new category
get '/categories/new' do
  erb :new_category
end



# POST to create a new product
post '/products' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Insert the new row into the products table.
  c.exec_params("INSERT INTO products (p_name, price, description) VALUES ($1,$2,$3)",
                  [params["p_name"], params["price"], params["description"]])

  # Assuming you created your products table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_product_id = c.exec_params("SELECT currval('products_id_seq');").first["currval"]
  c.close
  redirect "/products/#{new_product_id}"
end

# GET the show page for a particular product
get '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1;", [params[:id]]).first
  c.close

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product_category = c.exec_params("SELECT p.p_name, c.c_name, c.id FROM products as p INNER JOIN product_category AS pc
                                      ON pc.product_id = p.id INNER JOIN categories AS c ON pc.category_id = c.id 
                                      WHERE p.id =$1", [params["id"]])
  c.close  
  binding.pry

  erb :product
end

# Update a product
post '/products/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Update the product.
  c.exec_params("UPDATE products SET (p_name, price, description) = ($2, $3, $4) WHERE products.id = $1 ",
                [params["id"], params["p_name"], params["price"], params["description"]])
  c.close
  redirect "/products/#{params["id"]}"
end




# edit a product
get '/products/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product = c.exec_params("SELECT * FROM products WHERE products.id = $1", [params["id"]]).first
  c.close

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product_category = c.exec_params("SELECT p.p_name, c.c_name, c.id FROM products as p INNER JOIN product_category AS pc
                                      ON pc.product_id = p.id INNER JOIN categories AS c ON pc.category_id = c.id 
                                      WHERE p.id =$1", [params["id"]])
  erb :edit_product
end


# DELETE to delete a product
post '/products/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec_params("DELETE FROM products WHERE products.id = $1", [params["id"]])
  c.close
  redirect '/products'
end

# DELETE to delete a category from product
post '/products/:id/:c_id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @product_category = c.exec_params("DELETE * FROM products as p INNER JOIN product_category AS pc
                ON pc.product_id = p.id INNER JOIN categories AS c ON pc.category_id = c.id 
                WHERE p.id =$1 AND c.id=$2", [params["id"], params[:c_id]])
  redirect '/product/:id'
end






# POST to create a new category
post '/categories' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Insert the new row into the products table.
  c.exec_params("INSERT INTO categories (p_name) VALUES ($1)",
                  [params["p_name"].capitalize])

  # Assuming you created your products table with "id SERIAL PRIMARY KEY",
  # This will get the id of the product you just created.
  new_category_id = c.exec_params("SELECT currval('categories_id_seq');").first["currval"]
  c.close
  redirect "/categories"
end

# GET the show page for a particular category
get '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @category = c.exec_params("SELECT * FROM categories WHERE categories.id = $1;", [params[:id]]).first
  c.close

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @category_product = c.exec_params("SELECT c.c_name, p.p_name FROM categories as c INNER JOIN product_category AS pc
                                      ON pc.product_id = c.id INNER JOIN products AS p ON pc.category_id = p.id 
                                      WHERE c.id =$1", [params["id"]])
  c.close  
  erb :category
end

# Update a category
post '/categories/:id' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)

  # Update the category.
  c.exec_params("UPDATE categories SET (c_name) = ($2) WHERE categories.id = $1 ",
                [params["id"], params["c_name"]])
  c.close
  redirect "/categories/#{params["id"]}"
end



# edit a category
get '/categories/:id/edit' do
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  @category = c.exec_params("SELECT * FROM categories WHERE categories.id = $1", [params["id"]]).first
  c.close
  erb :edit_category
end


# DELETE to delete a category
post '/categories/:id/destroy' do

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec_params("DELETE FROM categories WHERE categories.id = $1", [params["id"]])
  c.close
  redirect '/categories'
end





######METHODS######


# Create Table methods
def create_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec %q{
  CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    p_name varchar(255),
    price decimal,
    description text
  );
  }
  c.close
end

def create_categories_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec %q{
    CREATE TABLE categories (
      id SERIAL PRIMARY KEY,
      c_name text
      );
  }
  c.close
end

def create_product_category_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec %q{
    CREATE TABLE product_category (
      id SERIAL PRIMARY KEY,
      product_id integer,
      category_id integer
      );
  }
  c.close
end


# Drop Table Methods
def drop_categories_table
  c = PGconn.new(:host => "localhost", :dbname => dbname)
  c.exec "DROP TABLE categories;"
  c.close
end



def drop_products_table
  c = PGconn.new(:host => "localhost", :dbname => dbname )
  c.exec "DROP TABLE products;"
  c.close
end

def drop_product_category_table
  c = PGconn.new(:host => "localhost", :dbname => dbname )
  c.exec "DROP TABLE product_category;"
  c.close
end




# Seed Table Methods
def seed_products_table
  products = [["Laser", "325", "Good for lasering."],
              ["Shoe", "23.4", "Just the left one."],
              ["Wicker Monkey", "78.99", "It has a little wicker monkey baby."],
              ["Whiteboard", "125", "Can be written on."],
              ["Chalkboard", "100", "Can be written on.  Smells like education."],
              ["Podium", "70", "All the pieces swivel separately."],
              ["Bike", "150", "Good for biking from place to place."],
              ["Kettle", "39.99", "Good for boiling."],
              ["Toaster", "20.00", "Toasts your enemies!"],
             ]

  c = PGconn.new(:host => "localhost", :dbname => dbname)
  products.each do |p|
    c.exec_params("INSERT INTO products (p_name, price, description) VALUES ($1, $2, $3);", p)
  end
  c.close
end

def seed_categories_table
  categories = [["Education"],["Home"],["Misc"],["Cheap"],["Expensive"]]

  c = PGconn.new(:host => "localhost", :dbname => dbname)

  categories.each do |category|
    c.exec_params("INSERT INTO categories (c_name) VALUES ($1);", category)
  end
  c.close
end

def seed_product_category_table
  id_pairs = [[1,1] , [1,5] , [2,3] , [2,4] , 
              [3,3] , [3,5] , [4,1] , [4,5] ,
              [5,1] , [5,5] , [6,1] , [6,2] ,
              [6,4] , [7,3] , [7,5] , [8,2] ,
              [8,4] , [9,2] , [9,4]
            ]

  c = PGconn.new(:host => "localhost", :dbname => dbname)

  id_pairs.each do |item|
    c.exec_params("INSERT INTO product_category (product_id, category_id) VALUES ($1, $2);", item)
  end
  c.close
end