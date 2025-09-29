def test_crud_items(client):
# empty list
    r = client.get("/items")
    assert r.status_code == 200
    assert r.json() == []


    # create
    r = client.post("/items", json={"name": "notebook", "price": 12.5})
    assert r.status_code == 201
    item = r.json()
    assert item["id"] >= 1
    assert item["name"] == "notebook"


    # get
    r = client.get(f"/items/{item['id']}")
    assert r.status_code == 200


    # delete
    r = client.delete(f"/items/{item['id']}")
    assert r.status_code == 204


    # 404
    r = client.get(f"/items/{item['id']}")
    assert r.status_code == 404