class User
	$all_orders= Hash.new
	attr_accessor :name, :balance, :password 
	def initialize(name,password,address,balance)
		@name=name
		@password=password
		@address=address
		@balance=balance
		#His personel orders which he bought
		@orders=Array.new
		#His personel products which he wants to sell
		@products= Array.new
		#Products he sold
		@sold= Array.new
	end
	def buy(product,quantity)
		# binding.pry
		if @balance >= product.price*quantity  and product.qty.to_i >= quantity
			puts "\n\n##succesfully bought!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n\n"
			# Money detected from buyer
			deduct(product.price,quantity)
			# Seller get money
			product.seller.add(product.price,quantity)
			# Personel Orders
			@orders.push([product,quantity])
			product.seller.sell(product)
			# Edit the quantity in general
			product.editQty(quantity,product.name)
			# binding.pry
			# Local hash
			$all_orders.store(@name,product)
			# Orders Hash Redis
			# @@temp.store(product.name,quantity)
			if $ord.hexists("user:"+@name,product.name)
				temp_counter= quantity+$ord.hmget("user:"+@name,product.name)
				$ord.hmset("user:"+@name,product.name,temp_counter)
			else
				$ord.hmset("user:"+@name,product.name,quantity)
			end
			# binding.pry
		elsif product.qty.to_i < quantity
			puts "\n\n#{quantity} Products unavailable!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n"
		else
			puts "\n\nInsufficient Balance"
		end
	end
	def addProduct(product)
		@products.push(product)
		$prod.store(product.name,product)
	end
	def deduct(price,quantity)
		$users.decrby(@name,price*quantity)
		@balance-=(price*quantity)
	end
	def getOrders
		puts "#{@name}'s Orders:-\n"
		for i in 0..@orders.length-1
			puts "\tName:#{@name}\tProduct Name:#{@orders[i][0].name}\tQuantity:#{@orders[i][1]}\tRs.#{@orders[i][0].price}*#{@orders[i][1]}\tSeller:#{@orders[i][0].seller.name}\n"
		end
		puts "\n"
	end
	def add(money,quantity)
		$users.incrby(@name,money*quantity)
		@balance+=(money*quantity)
	end
	def sell(product)
		@sold.push(product)
	end
	def displayBalance
		puts "\n--------------------------"
		# binding.pry
		puts "#{@name}'s balance is #{$users.get(@name)}"
		puts "--------------------------\n\n"
	end
	def self.allOrders
		puts "\n\n"
		$use.each do |u|
			# binding.pry
			p u.name
			p $ord.hscan_each("user:"+u.name).to_a
			# puts "\tName:#{u.name}\tProduct Name:#{$ord.get(u.name)}\tQuantity:#{$ord.hmget("user:"+u.name,)}
		end
		puts "\n\n\n"
	end
end

class Product
	attr_accessor :name, :qty, :price, :seller

	def initialize(name,qty,price,seller)
		@name=name
		@qty=qty
		@price=price
		@seller=seller
		@qty_sold=0
	end

	def self.display(n_user)
		puts "\n\nAll Products:-\n"
		$prod.each do |k,v|
			if v.seller.name != n_user.name
				puts "\tName:#{k}\tQuantity:#{$qtyHash.get(k)}\tPrice:#{v.price}\tSeller:#{v.seller.name}"
			end
		end
		puts "\n"
	end

	def self.display_yours(n_user)
		puts "Your Products:-\n"
		$prod.each do |k,v|
			if v.seller.name == n_user.name
				puts "\tName:#{k}\tQuantity:#{$qtyHash.get(k)}\tPrice:#{v.price}\tSeller:#{v.seller.name}"
			end
		end
		puts "\n"
	end

	def editQty(count,proname)
		# binding.pry
		@qty = @qty.to_i - count
		$qtyHash.decrby(proname,count)
		# binding.pry
		@qty_sold+=count
	end
end

class Login

	def self.validation
		puts "Enter username:-"
		username=gets.chomp.strip
		$use.each do |u|
 			if u.name==username && validate_password(u)
				puts "\n\n\n"
				return u
			end				
		end
		puts "Incorrect username!"
		validation
	end

	def self.validate_password(u)
		puts "Enter password:-"
		passwd=gets.chomp.strip
		if passwd==u.password
			return true
		else
			puts "Incorrect password!"
			bool=validate_password(u)
		end
		return false||bool
	end
end

require "redis"
require "pry"
$prod= Hash.new
$qtyHash= Redis.new
$ord= Redis.new
$users= Redis.new

# $ord.hdel("user:Heman","Specs")
# $ord.hdel("user:Heman","jeans")
# $ord.hdel("user:Heman","Mug")
# $ord.hdel("user:Dev","Puma Shoes")
# $ord.hdel("user:Dev","T-brush")


$qtyHash.set("Watch",2) if $qtyHash.get("Watch") == nil
$qtyHash.set("T-brush",10) if $qtyHash.get("T-brush") == nil
$qtyHash.set("boquet",1) if $qtyHash.get("boquet") == nil
$qtyHash.set("Puma Shoes",5) if $qtyHash.get("Puma Shoes") == nil
if $qtyHash.get("Mug")== nil
	$qtyHash.set("Mug",2)
end
$qtyHash.set("jeans",6) if $qtyHash.get("jeans") == nil
$qtyHash.set("Specs",1) if $qtyHash.get("Specs") == nil

$users.set("Heman",25000) if $users.get("Heman") == nil
$users.set("Dev",30000) if $users.get("Dev") == nil
# binding.pry

seller1= User.new("Heman","007","cbe",$users.get("Heman").to_i)
seller1.addProduct(Product.new("Watch",$qtyHash.get("Watch").to_i,700,seller1))
seller1.addProduct(Product.new("T-brush",$qtyHash.get("T-brush").to_i,20,seller1))
seller1.addProduct(Product.new("boquet",$qtyHash.get("boquet").to_i,70,seller1))
seller1.addProduct(Product.new("Puma Shoes",$qtyHash.get("Puma Shoes").to_i,2089,seller1))
buyer1	= User.new("Dev","123","chennai",$users.get("Dev").to_i)
buyer1.addProduct(Product.new("Mug",$qtyHash.get("Mug").to_i,120,buyer1))
buyer1.addProduct(Product.new("jeans",$qtyHash.get("jeans").to_i,899,buyer1))
buyer1.addProduct(Product.new("Specs",$qtyHash.get("Specs").to_i,1200,buyer1))

$use=[seller1,buyer1]

# Note : This user array lists the users. In order to peoceed you must log into as a user
superUser=Login.validation

Product.display_yours(superUser)

while true
	puts "Update Stock, Enter product you want to add, Q to quit :-"
	prod=gets.chomp.strip
	if prod=="Q"||prod=="q" then break; end
	puts "Enter quantity :-"
	cont=gets.chomp.to_i
	if $qtyHash.exists(prod) then $qtyHash.incrby(prod,cont); end
	puts "Done!!"
end

Product.display(superUser)
superUser.displayBalance
while true
	flag=true
	puts "#{superUser.name}, Enter the product you want to buy, bye to exit	 :-"
	prod=gets.chomp.strip
	if prod=="bye" then break; end	
	$prod.each_key do |key|
		if key.downcase==prod.downcase
			puts "Enter quantity :-"
			qty=gets.chomp.to_i
			superUser.buy($prod[key],qty)
			# Make individual changes here below
			# superUser.getOrders
			flag=true
			break
		else
			flag=false
		end
	end
	# binding.pry
	if flag==false then redo; end
	User.allOrders
	superUser.displayBalance
	Product.display(superUser)
end