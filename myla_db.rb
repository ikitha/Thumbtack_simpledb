#@database contains the data
@database = {}
#@begin is the transaction array
@begin = []
#counts switches on a BEGIN which determines how the @database hash is written
@count = 0
#first time begin is typed
@first_time = true
#first time program is opened
@open = true
#stores occurences of values
@values = {}
#@counter prevents invalid rollbacks with empty transactions
@counter = 1

#friendly help menu in case you forget commands!
def help
  puts "\n  SET name value -Set the variable name to the value value. No spaces! \n
  GET name – Print out the value of the variable name. \n
  UNSET name – Unset the variable name, making it just like that variable was never set. \n
  NUMEQUALTO value – Print out the number of variables that are currently set to value. \n
  BEGIN – Open a new transaction block. \n
  ROLLBACK – Undo all of the commands issued in the most recent transaction block, and close the block. \n
  COMMIT – Close all open transaction blocks, permanently applying the changes made in them. \n
  END – Exit the program."
end

def set name, value
  #If no transaction block is started, set hash keys and values to alter block instance
  if @count < 1
    @count = 0
    #create a values hash and store the value as the key and the number of occurences as the value
    if @database.empty?
      @database[name] = value
      @values[value] = 1
    else
      if @database.has_key?(name)
        #if the database already has this key, signal an overwrite on the key, subtract from @values and reset
        @values[@database[name]] -= 1
        @database[name] = value
        @values[@database[name]] = 1
      else
        @database[name] = value
        if @values.has_key?(value)
          @values[value] += 1
        else
          @values[value] = 1
        end
      end
    end
  else

  # @first_time is the initial time the user types BEGIN, or a BEGIN after a commit -- prevents duplication
  if @first_time
    #send the current database hash into a transaction block
    begin_transaction @database
  end
  @first_time = false
  @count = 0
  #previous data is the last instance of the database hash in the @begin array
  @previous_data = @begin.last
  #recreate the database hash when starting a new transaction block to prevent changes on previous blocks
  begin_transaction @database = {name => value}
  end
end

def get name
  if @database[name] != nil && @database.has_key?(name)
    puts @database[name]
  else
    puts "NULL"
  end
end

def unset name
  #remove occurence of value from values array for NUMEQUALTO
  if @values.has_key?(@database[name])
    @values[@database[name]] -= 1
  end
  set name, nil
end

def numequalto value
  #Pull occurences of a value from @values hash - O(1) constant time for lookup
  if @values[value] != nil
    puts @values[value]
  else
    puts "0"
  end
end

def begin_transaction data
  # If this is not the first transaction block, merge the previous blocks data into the new block
  if !@first_time
    data = @previous_data.merge(data)
    @begin << data
  else
    @begin << data
  end
  #reset the database hash to have the data of the last slot in the @begin array
  @database = @begin.last
  #recreate the values hash when a transaction is started, prevent duplication
  values = @database.values
  @values = {}
  values.each do |v|
    if @values.has_key?(v)
        @values[v] += 1
      else
        @values[v] = 1
    end
  end
end

def rollback
  @counter -= 1
  if @begin.length > 1
    #pop off last slot in the array, undoing last transaction data
    @begin.pop
    #reset the transaction data to the previous slot
    @database = @begin.last
    #recreate the values hash when a transaction is rolled back, prevent duplication
    values = @database.values
    @values = {}
    values.each do |v|
      if @values.has_key?(v)
          @values[v] += 1
        else
          @values[v] = 1
      end
    end
  else
    if @counter == 0
      puts "NO TRANSACTION"
    end
  end
end

def commit
  @counter = 1
  unless @begin.empty?
    #set the database hash to equal final slot, clear the array and reset the variable to signal a new BEGIN
    @database = @begin.last
    #recreate the values hash when a transaction is closed, prevent duplication
    values = @database.values
    @values = {}
    values.each do |v|
      if @values.has_key?(v)
          @values[v] += 1
        else
          @values[v] = 1
      end
    end
    @begin = []
    @first_time = true
  end
end

def run_stuff

  #Help menu prompt to see commands on opening of program
  if @open
    puts "Type HELP for a list of commands"
    @open = false
  end

  response = gets

  #EOF prevents error on CTRL-D
  if response.nil?
    return false
  else
    response = response.chomp.split(" ")
  end

  if response[0] == "SET"
    set response[1], response[2]
  elsif response[0] == "HELP"
    help
  elsif response[0] == "GET"
    get response[1]
  elsif response[0] == "UNSET"
    unset response[1]
  elsif response[0] == "NUMEQUALTO"
    numequalto response[1]
  elsif response[0] == "BEGIN"
    @previous_data = @database
    @count = 1
    @counter += 1
  elsif response[0] == "ROLLBACK"
    rollback
  elsif response[0] == "COMMIT"
    commit
  elsif response[0] == "END"
    return false
  end
  run_stuff
end

run_stuff