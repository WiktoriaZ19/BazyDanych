# Dokumentowe bazy danych – MongoDB

Ćwiczenie/zadanie

---

**Imiona i nazwiska autorów: Wiktoria Zalińśka, Magdalena Wilk**

---

Odtwórz z backupu bazę `north0`

```
mongorestore --nsInclude='north0.*' ./dump/
```

```
use north0
```

Baza `north0` jest kopią relacyjnej bazy danych `Northwind`

- poszczególne kolekcje odpowiadają tabelom w oryginalnej bazie `Northwind`

# Wprowadzenie

zapoznaj się ze strukturą dokumentów w bazie `North0`

```js
db.customers.find();
db.orders.find();
db.orderdetails.find();
```

# Operacje wyszukiwania danych, przetwarzanie dokumentów

# Zadanie 1

stwórz kolekcję `OrdersInfo` zawierającą następujące dane o zamówieniach

- kolekcję `OrdersInfo` należy stworzyć przekształcając dokumenty w oryginalnych kolekcjach `customers, orders, orderdetails, employees, shippers, products, categories, suppliers` do kolekcji w której pojedynczy dokument opisuje jedno zamówienie

```js
[
  {
    "_id": ...

    OrderID": ... numer zamówienia

    "Customer": {  ... podstawowe informacje o kliencie skladającym
      "CustomerID": ... identyfikator klienta
      "CompanyName": ... nazwa klienta
      "City": ... miasto
      "Country": ... kraj
    },

    "Employee": {  ... podstawowe informacje o pracowniku obsługującym zamówienie
      "EmployeeID": ... idntyfikator pracownika
      "FirstName": ... imie
      "LastName": ... nazwisko
      "Title": ... stanowisko

    },

    "Dates": {
       "OrderDate": ... data złożenia zamówienia
       "RequiredDate": data wymaganej realizacji
    }

    "Orderdetails": [  ... pozycje/szczegóły zamówienia - tablica takich pozycji
      {
        "UnitPrice": ... cena
        "Quantity": ... liczba sprzedanych jednostek towaru
        "Discount": ... zniżka
        "Value": ... wartośc pozycji zamówienia
        "product": { ... podstawowe informacje o produkcie
          "ProductID": ... identyfikator produktu
          "ProductName": ... nazwa produktu
          "QuantityPerUnit": ... opis/opakowannie
          "CategoryID": ... identyfikator kategorii do której należy produkt
          "CategoryName" ... nazwę tej kategorii
        },
      },
      ...
    ],

    "Freight": ... opłata za przesyłkę
    "OrderTotal"  ... sumaryczna wartosc sprzedanych produktów

    "Shipment" : {  ... informacja o wysyłce
        "Shipper": { ... podstawowe inf o przewoźniku
           "ShipperID":
            "CompanyName":
        }
        ... inf o odbiorcy przesyłki
        "ShipName": ...
        "ShipAddress": ...
        "ShipCity": ...
        "ShipCountry": ...
    }
  }
]
```

Polecenia tworzące kolekcję `OrdersInfo`:

```js
db.orders.aggregate([
  {
    $lookup: {
      from: "customers",
      localField: "CustomerID",
      foreignField: "CustomerID",
      as: "customer",
    },
  },
  { $unwind: "$customer" },

  {
    $lookup: {
      from: "orderdetails",
      localField: "OrderID",
      foreignField: "OrderID",
      as: "orderdetails",
    },
  },

  {
    $addFields: {
      Orderdetails: {
        $map: {
          input: "$orderdetails",
          as: "item",
          in: {
            UnitPrice: "$$item.UnitPrice",
            Quantity: "$$item.Quantity",
            Discount: "$$item.Discount",
            Value: {
              $multiply: [
                "$$item.UnitPrice",
                "$$item.Quantity",
                { $subtract: [1, "$$item.Discount"] },
              ],
            },
            ProductID: "$$item.ProductID",
          },
        },
      },
    },
  },

  {
    $addFields: {
      OrderTotal: {
        $sum: {
          $map: {
            input: "$Orderdetails",
            as: "item",
            in: "$$item.Value",
          },
        },
      },
    },
  },

  {
    $lookup: {
      from: "employees",
      localField: "EmployeeID",
      foreignField: "EmployeeID",
      as: "employee",
    },
  },
  { $unwind: "$employee" },

  {
    $lookup: {
      from: "shippers",
      localField: "ShipVia",
      foreignField: "ShipperID",
      as: "shipper",
    },
  },
  { $unwind: "$shipper" },

  {
    $lookup: {
      from: "products",
      localField: "Orderdetails.ProductID",
      foreignField: "ProductID",
      as: "ProductData",
    },
  },

  {
    $lookup: {
      from: "categories",
      localField: "ProductData.CategoryID",
      foreignField: "CategoryID",
      as: "CategoryData",
    },
  },

  {
    $addFields: {
      Orderdetails: {
        $map: {
          input: "$Orderdetails",
          as: "item",
          in: {
            UnitPrice: "$$item.UnitPrice",
            Quantity: "$$item.Quantity",
            Discount: "$$item.Discount",
            Value: "$$item.Value",
            Product: {
              $let: {
                vars: {
                  prod: {
                    $arrayElemAt: [
                      {
                        $filter: {
                          input: "$ProductData",
                          as: "p",
                          cond: { $eq: ["$$p.ProductID", "$$item.ProductID"] },
                        },
                      },
                      0,
                    ],
                  },
                },
                in: {
                  ProductID: "$$prod.ProductID",
                  ProductName: "$$prod.ProductName",
                  QuantityPerUnit: "$$prod.QuantityPerUnit",
                  CategoryID: "$$prod.CategoryID",
                  CategoryName: {
                    $let: {
                      vars: {
                        cat: {
                          $arrayElemAt: [
                            {
                              $filter: {
                                input: "$CategoryData",
                                as: "c",
                                cond: {
                                  $eq: ["$$c.CategoryID", "$$prod.CategoryID"],
                                },
                              },
                            },
                            0,
                          ],
                        },
                      },
                      in: "$$cat.CategoryName",
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  },

  {
    $project: {
      _id: 1,
      OrderID: "$OrderID",
      Customer: {
        CustomerID: "$customer.CustomerID",
        CompanyName: "$customer.CompanyName",
        City: "$customer.City",
        Country: "$customer.Country",
      },

      Employee: {
        EmployeeID: "$employee.EmployeeID",
        FirstName: "$employee.FirstName",
        LastName: "$employee.LastName",
        Title: "$employee.Title",
      },

      Dates: {
        OrderDate: "$OrderDate",
        RequiredDate: "$RequiredDate",
      },

      Orderdetails: "$Orderdetails",

      Freight: "$Freight",
      OrderTotal: "$OrderTotal",
      Shipment: {
        Shipper: {
          ShipperID: "$shipper.ShipperID",
          CompanyName: "$shipper.CompanyName",
        },
        ShipName: "$ShipName",
        ShipAddress: "$ShipAddress",
        ShipCity: "$ShipCity",
        ShipCountry: "$ShipCountry",
      },
    },
  },

  {
    $out: "OrdersInfo",
  },
]);
```

# Zadanie 2

stwórz kolekcję `CustomerInfo` zawierającą następujące dane o każdym kliencie

- pojedynczy dokument opisuje jednego klienta

```js
[
  {
    "_id": ...

    "CustomerID": ... identyfikator klienta
    "CompanyName": ... nazwa klienta
    "City": ... miasto
    "Country": ... kraj

	"Orders": [ ... tablica zamówień klienta o strukturze takiej jak w punkcie a) (oczywiście bez informacji o kliencie)

	]


]
```

# Zadanie 3

Napisz polecenie/zapytanie: Dla każdego klienta pokaż wartość zakupionych przez niego produktów z kategorii 'Confections' w 1997r

- Spróbuj napisać to zapytanie wykorzystując

  - oryginalne kolekcje (`customers, orders, orderdertails, products, categories`)
  - kolekcję `OrderInfo`
  - kolekcję `CustomerInfo`

- porównaj zapytania/polecenia/wyniki
  - zamieść odpowiedni komentarz
    - które wersje zapytań były "prostsze"

```js
[
  {
    "_id":

    "CustomerID": ... identyfikator klienta
    "CompanyName": ... nazwa klienta
	"ConfectionsSale97": ... wartość zakupionych przez niego produktów z kategorii 'Confections'  w 1997r

  }
]
```

# Zadanie 4

Napisz polecenie/zapytanie: Dla każdego klienta poaje wartość sprzedaży z podziałem na lata i miesiące
Spróbuj napisać to zapytanie wykorzystując - oryginalne kolekcje (`customers, orders, orderdertails, products, categories`) - kolekcję `OrderInfo` - kolekcję `CustomerInfo`

- porównaj zapytania/polecenia/wyniki
  - zamieść odpowiedni komentarz
    - które wersje zapytań były "prostsze"

```js
[
  {
    "_id":

    "CustomerID": ... identyfikator klienta
    "CompanyName": ... nazwa klienta

	"Sale": [ ... tablica zawierająca inf o sprzedazy
	    {
            "Year":  ....
            "Month": ....
            "Total": ...
	    }
	    ...
	]
  }
]
```

```

---

Punktacja:

|         |     |
| ------- | --- |
| zadanie | pkt |
| 1       | 3   |
| 2       | 3   |
| 3       | 3   |
| 4       | 3   |
| razem   | 12   |



```
