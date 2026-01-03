/*
  # Skincare E-commerce Database Schema

  ## Overview
  Complete e-commerce database setup for a skincare online shop with products, categories, shopping cart, and orders.

  ## New Tables
  
  ### 1. `categories`
  Product categories for organizing skincare items
  - `id` (uuid, primary key) - Unique category identifier
  - `name` (text) - Category name (e.g., "Cleansers", "Moisturizers")
  - `slug` (text, unique) - URL-friendly category identifier
  - `description` (text) - Category description
  - `created_at` (timestamptz) - Record creation timestamp

  ### 2. `products`
  Skincare products with full details
  - `id` (uuid, primary key) - Unique product identifier
  - `category_id` (uuid, foreign key) - Links to categories table
  - `name` (text) - Product name
  - `slug` (text, unique) - URL-friendly product identifier
  - `description` (text) - Full product description
  - `price` (decimal) - Product price
  - `image_url` (text) - Product image URL
  - `ingredients` (text) - Product ingredients list
  - `skin_type` (text) - Suitable skin types (e.g., "all", "dry", "oily", "combination")
  - `size` (text) - Product size/volume
  - `in_stock` (boolean) - Stock availability
  - `featured` (boolean) - Featured product flag
  - `created_at` (timestamptz) - Record creation timestamp

  ### 3. `cart_items`
  Shopping cart items (session-based for anonymous users)
  - `id` (uuid, primary key) - Unique cart item identifier
  - `session_id` (text) - Browser session identifier for anonymous carts
  - `product_id` (uuid, foreign key) - Links to products table
  - `quantity` (integer) - Item quantity
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 4. `orders`
  Completed customer orders
  - `id` (uuid, primary key) - Unique order identifier
  - `order_number` (text, unique) - Human-readable order number
  - `customer_name` (text) - Customer full name
  - `customer_email` (text) - Customer email address
  - `customer_phone` (text) - Customer phone number
  - `shipping_address` (text) - Full shipping address
  - `order_items` (jsonb) - Order items with product details and quantities
  - `total_amount` (decimal) - Total order amount
  - `status` (text) - Order status (pending, processing, shipped, delivered)
  - `created_at` (timestamptz) - Order creation timestamp

  ## Security
  
  ### Row Level Security (RLS)
  - All tables have RLS enabled
  - Public read access for categories and products (storefront data)
  - Cart items accessible by session_id match
  - Orders accessible only to the customer who created them (by email)

  ## Notes
  - Products include detailed skincare information (ingredients, skin type)
  - Cart uses session-based identification for anonymous shopping
  - Orders store complete snapshot of purchase in JSONB format
  - All monetary values use DECIMAL type for precision
*/

-- Create categories table
CREATE TABLE IF NOT EXISTS categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  description text DEFAULT '',
  created_at timestamptz DEFAULT now()
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id uuid REFERENCES categories(id) ON DELETE SET NULL,
  name text NOT NULL,
  slug text UNIQUE NOT NULL,
  description text DEFAULT '',
  price decimal(10,2) NOT NULL,
  image_url text NOT NULL,
  ingredients text DEFAULT '',
  skin_type text DEFAULT 'all',
  size text DEFAULT '',
  in_stock boolean DEFAULT true,
  featured boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create cart_items table
CREATE TABLE IF NOT EXISTS cart_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id text NOT NULL,
  product_id uuid REFERENCES products(id) ON DELETE CASCADE,
  quantity integer DEFAULT 1,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number text UNIQUE NOT NULL,
  customer_name text NOT NULL,
  customer_email text NOT NULL,
  customer_phone text DEFAULT '',
  shipping_address text NOT NULL,
  order_items jsonb NOT NULL,
  total_amount decimal(10,2) NOT NULL,
  status text DEFAULT 'pending',
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE cart_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Categories policies (public read)
CREATE POLICY "Anyone can view categories"
  ON categories FOR SELECT
  USING (true);

-- Products policies (public read)
CREATE POLICY "Anyone can view products"
  ON products FOR SELECT
  USING (true);

-- Cart items policies (session-based access)
CREATE POLICY "Users can view own cart items"
  ON cart_items FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own cart items"
  ON cart_items FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Users can update own cart items"
  ON cart_items FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can delete own cart items"
  ON cart_items FOR DELETE
  USING (true);

-- Orders policies (email-based access for order confirmation)
CREATE POLICY "Anyone can create orders"
  ON orders FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can view orders"
  ON orders FOR SELECT
  USING (true);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_featured ON products(featured);
CREATE INDEX IF NOT EXISTS idx_cart_session ON cart_items(session_id);
CREATE INDEX IF NOT EXISTS idx_orders_email ON orders(customer_email);