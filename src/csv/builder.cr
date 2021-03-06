class CSV::Builder
  def initialize(@io)
    @first_cell_in_row = true
  end

  def row
    yield Row.new(self)
    @io << "\n"
    @first_cell_in_row = true
  end

  def row(values : Enumerable)
    row do |row|
      values.each do |value|
        row << value
      end
    end
  end

  def row(*values)
    row values
  end

  def cell
    append_cell do
      yield @io
    end
  end

  def quote_cell(value)
    append_cell do
      @io << '"'
      value.each_byte do |byte|
        case byte
        when '"'.ord
          @io << %("")
        else
          @io.write_byte byte
        end
      end
      @io << '"'
    end
  end

  private def append_cell
    @io << "," unless @first_cell_in_row
    yield
    @first_cell_in_row = false
  end

  struct Row
    def initialize(@builder)
    end

    def <<(value : String)
      if needs_quotes?(value)
        @builder.quote_cell value
      else
        @builder.cell { |io| io << value }
      end
    end

    def <<(value : Nil | Bool | Char | Number | Symbol)
      @builder.cell { |io| io << value }
    end

    def <<(value)
      self << value.to_s
    end

    def concat(values : Enumerable)
      values.each do |value|
        self << value
      end
    end

    def concat(*values)
      concat values
    end

    def skip_cell
      self << nil
    end

    private def needs_quotes?(value)
      value.each_byte do |byte|
        case byte.chr
        when ',', '\n', '"'
          return true
        end
      end
      false
    end
  end
end
