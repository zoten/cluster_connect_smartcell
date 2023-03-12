import * as Vue from "https://cdn.jsdelivr.net/npm/vue@3.2.26/dist/vue.esm-browser.prod.js";

export function init(ctx, payload) {
  ctx.importCSS("main.css");
  ctx.importCSS(
    "https://fonts.googleapis.com/css2?family=Inter:wght@400;500&display=swap"
  );

  const app = Vue.createApp({
    template: `
        <div class="app">
        <!-- Info Messages -->
        <div id="info-box" class="info-box">
          <p>Please note that every time this cell is evaluated, a new atom based on
          <span>secret's</span> value will be created. The same applies for <span>Module</span>
          and <span>Function</span> fields. Be sure to understand what it means for the BEAM VM! 🙏</p>
          <p>Please note also that arguments field is evaluated through <span>Code.eval_string/1</span>
          so please make sure you let connect to this livebook with trusted people only! 🙏</p>
        </div>

        <form @change="handleFieldChange">
          <div class="container">
            <div class="root">
              <BaseInput
                name="target_node"
                label="Node"
                type="text"
                placeholder="node@host"
                v-model="rootFields.target_node"
                class="input--md"
              />
              <BaseInput
                name="erlang_cookie"
                label="Cookie"
                type="text"
                placeholder="secret"
                v-model="rootFields.erlang_cookie"
                class="input--md"
              />
            </div>

            <div class="layers">
              <div class="row">
                <CommonInput
                  name="module"
                  label="Module"
                  type="text"
                  placeholder="MyModule"
                  :layer="index"
                  v-model="rootFields.module"
                  class="input--md"
                  :required
                />

                <CommonInput
                  name="function"
                  label="Function"
                  type="text"
                  :layer="index"
                  placeholder=":my_function"
                  v-model="rootFields.function"
                  class="input--md"
                  :required
                />
                <div class="field"></div>
              </div>

              <div class="row">
                <CommonInput
                  name="arguments"
                  label="Arguments"
                  type="text"
                  :layer="index"
                  placeholder="[1, 2, 3]"
                  v-model="rootFields.arguments"
                  class="input--lg"
                  :required
                />
              </div>
            </div>
          </div>
        </form>
        </div>
      `,
    data() {
      return {
        rootFields: payload.root_fields,
      }
    },

    methods: {
      handleFieldChange(event) {
        const { name, value } = event.target;
        ctx.pushEvent("update_field", { field: name, value });
      },
    },

    components: {
      BaseInput: {
        props: {
          label: {
            type: String,
            default: "",
          },
          modelValue: {
            type: [String, Number],
            default: "",
          },
        },
        template: `
          <div class="root-field">
            <label class="input-label">{{ label }}</label>
            <input
              :value="modelValue"
              @input="$emit('update:modelValue', $event.target.value)"
              v-bind="$attrs"
              class="input"
            >
          </div>
        `,
      },
      CommonInput: {
        props: {
          label: {
            type: String,
            default: "",
          },
          modelValue: {
            type: [String, Number],
            default: "",
          },
        },
        template: `
          <div class="field">
            <label class="input-label">{{ label }}</label>
            <input
              :value="modelValue"
              @input="$emit('update:modelValue', $event.target.value)"
              v-bind="$attrs"
              class="input"
            >
          </div>
        `,
      },
    }
  }).mount(ctx.root);

  ctx.handleEvent("update_root", ({ fields }) => {
    setRootValues(fields);
  });

  ctx.handleEvent("update_binding", ({ fields }) => {
    console.log("New binding: " + fields)
  });

  ctx.handleSync(() => {
    // Synchronously invokes change listeners
    document.activeElement &&
      document.activeElement.dispatchEvent(
        new Event("change", { bubbles: true })
      );
  });

  function setRootValues(fields) {
    for (const field in fields) {
      app.rootFields[field] = fields[field];
    }
  }
};
