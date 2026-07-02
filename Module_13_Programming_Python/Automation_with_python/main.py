import openxyl

inv_file = openxyl.load_workbook("")

product_list = inv_file[""]

product_per_supplier = {}

print(product_list.max_row)

for product_row in range(2, product_list.max_row + 1):
    supplier_name = product_list.cell(product_row, 4).value
    inventory_num = product_list.cell(product_row, 2).value

    if supplier_name in product_per_supplier:
        current_num = product_per_supplier[supplier_name]
        product_per_supplier[supplier_name] = current_num + inventory_num
    else:
        product_per_supplier[supplier_name] = inventory_num

inv_file.save("updated_inv.xlsx")

inv_file.close()